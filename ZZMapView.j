// ZZMapView.j
//
// Created by Stephen Ierodiaconou,
// Copyright (c) 2010, Architecture 00 Ltd. 
// Portions Francisco Tolmasky, Copyright (c) 2010 280 North, Inc.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

@import <Foundation/CPObject.j>
@import <AppKit/CPView.j>

var ZZMapTypeHybrid = 'hybrid',
    ZZMapTypeRoadMap = 'roadmap',
    ZZMapTypeSatellite = 'satellite',
    ZZMapTypeTerrain = 'terrain';

/*
    MapPoint:
    {latitude: a, longitude: b}
*/

@implementation ZZMapView : CPView
{
    id                      delegate            @accessors;

    DOMElement              DOMMapElement;
    Object                  map                 @accessors;
    
    MapPoint                centerPoint         @accessors;
    float                   zoomLevel           @accessors;
    MapTypeId               mapType;            @accessors;
}

- (id)initWithFrame:(CGRect)frame
{
    [self initWithFrame:frame delegate:self center:{latitude:51.565828,longitude:-0.100034} zoom:15 mapType:ZZMapTypeHybrid];
}

- (id)initWithFrame:(CGRect)frame delegate:(id)d center:(MapPoint)center zoom:(float)zoom mapType:type
{
    if (self = [super initWithFrame:frame])
    {
        delegate = d;
        centerPoint = center;
        zoomLevel = zoom;
        mapType = type;
        
        [self _buildDOM];
    }
    return self;
}

// This method is adapted from http://github.com/280north/mapkit
- (void)_buildDOM
{
    performWhenGoogleMapsScriptLoaded(function()
    {
        DOMMapElement = document.createElement("div");
        DOMMapElement.id = "MapDiv" + [self UID];

        var style = DOMMapElement.style,
            bounds = [self bounds],
            width = CGRectGetWidth(bounds),
            height = CGRectGetHeight(bounds);

        style.overflow = "hidden";
        style.position = "absolute";
        style.visibility = "visible";
        style.zIndex = 0;
        style.left = -width + "px";
        style.top = -height + "px";
        style.width = width + "px";
        style.height = height + "px";

        // Google Maps can't figure out the size of the div if it's not in the DOM tree,
        // so we have to temporarily place it somewhere on the screen to appropriately size it.
        document.body.appendChild(DOMMapElement);

        map = new google.maps.Map(DOMMapElement);
        
        switch (mapType)
        {
        case ZZMapTypeHybrid:
            map.setMapTypeId(google.maps.MapTypeId.HYBRID);
            break;
        case ZZMapTypeRoadMap:
            map.setMapTypeId(google.maps.MapTypeId.ROADMAP);
            break;
        case ZZMapTypeSatellite:
            map.setMapTypeId(google.maps.MapTypeId.SATELLITE);
            break;
        case ZZMapTypeTerrain:
            map.setMapTypeId(google.maps.MapTypeId.TERRAIN);
            break;
        default:
            map.setMapTypeId(google.maps.MapTypeId.HYBRID);
        }
        
        map.setCenter(new google.maps.LatLng(centerPoint.latitude, centerPoint.longitude));
        map.setZoom(zoomLevel);
        
        style.left = "0px";
        style.top = "0px";
        
        google.maps.event.trigger(map, 'resize');

        // Important: we had to remove this dom element before appending it somewhere else
        // or you will get WRONG_DOCUMENT_ERRs (4)
        document.body.removeChild(DOMMapElement);

        _DOMElement.appendChild(DOMMapElement);
        
        [self mapIsReady];
        
    });
}

// This method is adapted from http://github.com/280north/mapkit
- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];

    if (DOMMapElement)
    {
        var bounds = [self bounds],
            style = DOMMapElement.style;

        style.width = CGRectGetWidth(bounds) + "px";
        style.height = CGRectGetHeight(bounds) + "px";

        google.maps.event.trigger(map, 'resize');
    }
}

- (void)mapIsReady
{
    console.log('the map is ready');
    
    if (delegate)
        [delegate mapIsReady:self];
}

@end


var GoogleMapsScriptQueue   = [];
// This method is adapted from http://github.com/280north/mapkit
var performWhenGoogleMapsScriptLoaded = function(/*Function*/ aFunction)
{
    GoogleMapsScriptQueue.push(aFunction);

    performWhenGoogleMapsScriptLoaded = function()
    {
        GoogleMapsScriptQueue.push(aFunction);
    }

    // Maps is already loaded
    if (window.google && google.maps && google.maps.Map)
        _MKMapViewMapsLoaded();

    else
    {
        var DOMScriptElement = document.createElement("script");
        
        DOMScriptElement.src = "http://maps.google.com/maps/api/js?sensor=false&callback=_MKMapViewMapsLoaded";
        DOMScriptElement.type = "text/javascript";

        document.getElementsByTagName("head")[0].appendChild(DOMScriptElement);
    }
}

// This method is adapted from http://github.com/280north/mapkit
function _MKMapViewMapsLoaded()
{
    performWhenGoogleMapsScriptLoaded = function(/*Function*/ aFunction)
    {
        aFunction();
    }

    var index = 0,
        count = GoogleMapsScriptQueue.length;

    for (; index < count; ++index)
        GoogleMapsScriptQueue[index]();

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}


@implementation ZZMapView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {

        [self _buildDOM];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

}

@end
