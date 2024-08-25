#ifndef CHARACTER_MACRO_INCLUDED
#define CHARACTER_MACRO_INCLUDED

float4 TransformHClipToViewPortPos(float4 positionCS)
{
    float4 o = positionCS * 0.5;
    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
    o.zw = positionCS.zw;
    return o / o.w ;
}

#endif