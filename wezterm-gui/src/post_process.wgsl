const scanlineCount:u32             = 128u;
const scaleFactor:f32               = 1.0;
const ENABLE_CURVE:bool             = true;
const ENABLE_OVERSCAN:bool          = true;
const ENABLE_BLOOM:bool             = true;
const ENABLE_BLUR:bool              = true;
const ENABLE_GRAYSCALE:bool         = true;
const ENABLE_BLACKLEVEL:bool        = true;
const ENABLE_REFRESHLINE:bool       = true;
const ENABLE_SCANLINES:bool         = true;
const ENABLE_TINT:bool              = true;
const ENABLE_GRAIN:bool             = true;
// Settings - Curve
const CURVE_INTENSITY:f32      =   1.0;
// Settings - Overscan
const OVERSCAN_PERCENTAGE =     0.02;
// Settings - Bloom
const BLOOM_OFFSET          =  0.0015;
const BLOOM_STRENGTH        =  0.8;
// Settings - Blur
const BLUR_MULTIPLIER       =  1.05;
const BLUR_STRENGTH         =  0.2;
const BLUR_OFFSET           =  0.003;
// Settings - Grayscale
const GRAYSCALE_INTENSITY     =0.0;
const GRAYSCALE_GLEAM         =0.0;
const GRAYSCALE_LUMINANCE     =1.0;
const GRAYSCALE_LUMA          =0.0;
// Settings - Blacklevel

// const BLACKLEVEL_FLOOR        TINT_COLOR / 40

// Settings - Tint
// Colors variations from https://superuser.com/a/1206781
const TINT_COLOR      = TINT_AMBER;
const TINT_AMBER      =vec3<f32>(1.0, 0.7, 0.0); // P3 phosphor
const TINT_LIGHT_AMBER=vec3<f32>(1.0, 0.8, 0.0);
const TINT_GREEN_1    =vec3<f32>(0.2, 1.0, 0.0);
const TINT_APPLE_II   =vec3<f32>(0.2, 1.0, 0.2); // P1 phosphor
const TINT_GREEN_2    =vec3<f32>(0.0, 1.0, 0.2);
const TINT_APPLE_IIc  =vec3<f32>(0.4, 1.0, 0.4); // P24 phpsphor
const TINT_GREEN_3    =vec3<f32>(0.0, 1.0, 0.4);
const TINT_WARM       =vec3<f32>(1.0, 0.9, 0.8);
const TINT_COOL       =vec3<f32>(0.8, 0.9, 1.0);
// Settings - Gain
const GRAIN_INTENSITY = false;
// uniform vec3      iResolution;           // viewport resolution (in pixels)
// uniform float     iTime;                 // shader playback time (in seconds)
// uniform float     iTimeDelta;            // render time (in seconds)
// uniform float     iFrameRate;            // shader frame rate
// uniform int       iFrame;                // shader playback frame
// uniform float     iChannelTime[4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
// uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
// uniform vec4      iDate;                 // (year, month, day, time in seconds)
// uniform float     iSampleRate;           // sound sample rate (i.e., 44100)
struct PostProcessUniform {
  resolution: vec2<f32>,
  time: f32,
//   projection: mat4x4<f32>,
};

@group(0) @binding(0) var<uniform> uniforms: PostProcessUniform;

@group(1) @binding(0) var tex2d: texture_2d<f32>;
@group(1) @binding(1) var texsampler: sampler;
struct VertexOutput {
    @builtin(position) clip_position: vec4f,
};

@vertex
fn dummy_vs(
    @builtin(vertex_index) in_vertex_index: u32,
) -> VertexOutput {
    var output: VertexOutput;
    if in_vertex_index == 0u {
        output.clip_position = vec4<f32>(-1.0, -1.0, 0.0, 1.0);
    } else if (in_vertex_index == 1u) {
        output.clip_position = vec4<f32>(1.0, -1.0, 0.0, 1.0);
    } else if (in_vertex_index == 2u) {
        output.clip_position = vec4<f32>(-1.0, 1.0, 0.0, 1.0);
    } else if (in_vertex_index == 3u) {
        output.clip_position = vec4<f32>(1.0, -1.0, 0.0, 1.0);
    }else if (in_vertex_index == 4u) {
        output.clip_position = vec4<f32>(1.0, 1.0, 0.0, 1.0);
    }else if (in_vertex_index == 5u) {
        output.clip_position = vec4<f32>(-1.0, 1.0, 0.0, 1.0);
    }
            //    -1.0, -1.0, 0.0,
            // 1.0, -1.0, 0.0,
            // -1.0, 1.0, 0.0,
            // 1.0, -1.0, 0.0,
            // 1.0, 1.0, 0.0,
            // -1.0, 1.0, 0.0,
    return output;
}
@fragment
fn pp_fs(@builtin(position) fragCoord: vec4<f32>) -> @location(0) vec4f {
    let pos_normed = vec2(fragCoord.x / uniforms.resolution.x,fragCoord.y / uniforms.resolution.y);
    let uv = curve_uv(pos_normed,vec2(5.0,5.0));
    var color = textureSample(tex2d, texsampler, uv);
    color = vec4(drawScanline(color.rgb,pos_normed,0.7),color.a);
    // var color = vec4<f32>(pos_normed, 1.0 ,1.0);
    return color;
}
fn curve_uv(uv:vec2<f32>,curve_rate:vec2<f32>)-> vec2<f32>{
    // uv: 输入uv坐标
    // curve_rate: xy 方向的曲率
    var out = uv * 2.0 - 1.0;
    var offset = abs(out.yx) / curve_rate;
    out = out + out * offset * offset;
    out = out*0.5 + 0.5;
    return out;
}

 
fn drawScanline( color:vec3<f32>, uv:vec2<f32>, intensity:f32 ) -> vec3<f32>
{
    let x_res = uniforms.resolution.x;
    let y_res =uniforms.resolution.y;
    var scanline 	= clamp( (1.0-intensity) + intensity * cos( 3.14 * ( uv.y ) * y_res * 1.0 ), 0.0, 1.0 );
    // var scanline 	= clamp( (1.0-intensity) + intensity * cos( 3.14 * ( uv.y + 0.008 * uniforms.time ) * y_res * 1.0 ), 0.0, 1.0 );
    var grille 	= 0.85 + 0.15 * clamp( 1.5 * cos( 3.14 * uv.x * x_res * 1.0 ), 0.0, 1.0 );    
    var out = color* scanline * grille * 1.2;
    return out;
}
// fn blur(tex:texture_2d,uv:vec2<f32>,sigma:f32){
    

// }
// fn mainImage(fragCoord:vec2<f32> ) -> vec4<f32>
// {
//     // Normalized pixel coordinates (from 0 to 1)
//     var uv = fragCoord;

//     const centerOffset = -0.5;
    
//     var uvCentered = uv + centerOffset;
    
//     var uvNew = uvCentered * (1.0 + 0.5*vec2(4.0/3.0, 1.0) * length(uvCentered)) - centerOffset; //bar - centerOffset;
    
    
//     var float brightness = int(uvNew.y) / (int(uv.y) / scanlineCount) % 2 == 0 ? 1.0 : 0.5;
    
//     if uvNew.x >= 0.0 && uvNew.x <= 1.0 && uvNew.y >= 0.0 && uvNew.y <= 1.0 {
//         return vec4(vec3(brightness * texture(iChannel0, uvNew).x), 1);
//     }
//     else{
//         return vec4(0.0);
//     }
// }


