// Optical FFT Bloom v2.3 -- standalone shader; no add-on required.
// MIT License. See LICENSE.txt. Requires ReShade 6.8+, compute backend.
// Enter actual dimensions in ReShade's effect preprocessor definitions.
// Aperture N x N -> centred (N+1) x (N+1) kernel; one texel = one display pixel.
// No artistic resolution ceiling or silent clamping. Device/memory limits apply.
#ifndef OFB2_APERTURE_SIZE
#define OFB2_APERTURE_SIZE 1024
#endif
#ifndef OFB2_RENDER_DIVISOR
#define OFB2_RENDER_DIVISOR 4
#endif
#ifndef OFB2_SPECTRAL_SAMPLES
#define OFB2_SPECTRAL_SAMPLES 3
#endif
#ifndef OFB2_FFT_WIDTH
#define OFB2_FFT_WIDTH 0
#endif
#ifndef OFB2_FFT_HEIGHT
#define OFB2_FFT_HEIGHT 0
#endif
#if OFB2_APERTURE_SIZE < 2 || (OFB2_APERTURE_SIZE & (OFB2_APERTURE_SIZE-1))
#error "OFB2_APERTURE_SIZE must be an even power of two: 2, 4, 8, ... 1024, 2048, ..."
#endif
#if OFB2_RENDER_DIVISOR < 1
#error "OFB2_RENDER_DIVISOR must be a positive integer: 1 full, 2 half, 3 third, 4 quarter, ..."
#endif
#if OFB2_SPECTRAL_SAMPLES < 1
#error "OFB2_SPECTRAL_SAMPLES must be a positive integer. No shader-imposed sample-count ceiling."
#endif
#if OFB2_FFT_WIDTH < 0 || OFB2_FFT_HEIGHT < 0
#error "FFT dimensions must be zero (automatic) or positive integer minimum dimensions."
#endif
#if __RENDERER__ < 0xb000
#error "A compute-capable backend is required (D3D11+, Vulkan, OpenGL 4.3+)."
#endif
#define V2_N OFB2_APERTURE_SIZE
#define V2_K (V2_N+1)
#define V2_DIV OFB2_RENDER_DIVISOR
#define V2_W ((BUFFER_WIDTH+V2_DIV-1)/V2_DIV)
#define V2_H ((BUFFER_HEIGHT+V2_DIV-1)/V2_DIV)
// One scene texel covers DIV display pixels. Include the entire odd kernel.
#define V2_BORDER ((V2_N/2+V2_DIV-1)/V2_DIV+1)
#define V2_WAVES OFB2_SPECTRAL_SAMPLES

#if OFB2_FFT_WIDTH <= 2 && V2_W+2*V2_BORDER <= 2
#define V2_FX 2
#elif OFB2_FFT_WIDTH <= 4 && V2_W+2*V2_BORDER <= 4
#define V2_FX 4
#elif OFB2_FFT_WIDTH <= 8 && V2_W+2*V2_BORDER <= 8
#define V2_FX 8
#elif OFB2_FFT_WIDTH <= 16 && V2_W+2*V2_BORDER <= 16
#define V2_FX 16
#elif OFB2_FFT_WIDTH <= 32 && V2_W+2*V2_BORDER <= 32
#define V2_FX 32
#elif OFB2_FFT_WIDTH <= 64 && V2_W+2*V2_BORDER <= 64
#define V2_FX 64
#elif OFB2_FFT_WIDTH <= 128 && V2_W+2*V2_BORDER <= 128
#define V2_FX 128
#elif OFB2_FFT_WIDTH <= 256 && V2_W+2*V2_BORDER <= 256
#define V2_FX 256
#elif OFB2_FFT_WIDTH <= 512 && V2_W+2*V2_BORDER <= 512
#define V2_FX 512
#elif OFB2_FFT_WIDTH <= 1024 && V2_W+2*V2_BORDER <= 1024
#define V2_FX 1024
#elif OFB2_FFT_WIDTH <= 2048 && V2_W+2*V2_BORDER <= 2048
#define V2_FX 2048
#elif OFB2_FFT_WIDTH <= 4096 && V2_W+2*V2_BORDER <= 4096
#define V2_FX 4096
#elif OFB2_FFT_WIDTH <= 8192 && V2_W+2*V2_BORDER <= 8192
#define V2_FX 8192
#elif OFB2_FFT_WIDTH <= 16384 && V2_W+2*V2_BORDER <= 16384
#define V2_FX 16384
#elif OFB2_FFT_WIDTH <= 32768 && V2_W+2*V2_BORDER <= 32768
#define V2_FX 32768
#elif OFB2_FFT_WIDTH <= 65536 && V2_W+2*V2_BORDER <= 65536
#define V2_FX 65536
#elif OFB2_FFT_WIDTH <= 131072 && V2_W+2*V2_BORDER <= 131072
#define V2_FX 131072
#elif OFB2_FFT_WIDTH <= 262144 && V2_W+2*V2_BORDER <= 262144
#define V2_FX 262144
#elif OFB2_FFT_WIDTH <= 524288 && V2_W+2*V2_BORDER <= 524288
#define V2_FX 524288
#elif OFB2_FFT_WIDTH <= 1048576 && V2_W+2*V2_BORDER <= 1048576
#define V2_FX 1048576
#elif OFB2_FFT_WIDTH <= 2097152 && V2_W+2*V2_BORDER <= 2097152
#define V2_FX 2097152
#elif OFB2_FFT_WIDTH <= 4194304 && V2_W+2*V2_BORDER <= 4194304
#define V2_FX 4194304
#elif OFB2_FFT_WIDTH <= 8388608 && V2_W+2*V2_BORDER <= 8388608
#define V2_FX 8388608
#elif OFB2_FFT_WIDTH <= 16777216 && V2_W+2*V2_BORDER <= 16777216
#define V2_FX 16777216
#elif OFB2_FFT_WIDTH <= 33554432 && V2_W+2*V2_BORDER <= 33554432
#define V2_FX 33554432
#elif OFB2_FFT_WIDTH <= 67108864 && V2_W+2*V2_BORDER <= 67108864
#define V2_FX 67108864
#elif OFB2_FFT_WIDTH <= 134217728 && V2_W+2*V2_BORDER <= 134217728
#define V2_FX 134217728
#elif OFB2_FFT_WIDTH <= 268435456 && V2_W+2*V2_BORDER <= 268435456
#define V2_FX 268435456
#elif OFB2_FFT_WIDTH <= 536870912 && V2_W+2*V2_BORDER <= 536870912
#define V2_FX 536870912
#elif OFB2_FFT_WIDTH <= 1073741824 && V2_W+2*V2_BORDER <= 1073741824
#define V2_FX 1073741824
#else
#error "FFT dimension cannot be represented by a signed 32-bit dimension."
#endif
#if OFB2_FFT_HEIGHT <= 2 && V2_H+2*V2_BORDER <= 2
#define V2_FY 2
#elif OFB2_FFT_HEIGHT <= 4 && V2_H+2*V2_BORDER <= 4
#define V2_FY 4
#elif OFB2_FFT_HEIGHT <= 8 && V2_H+2*V2_BORDER <= 8
#define V2_FY 8
#elif OFB2_FFT_HEIGHT <= 16 && V2_H+2*V2_BORDER <= 16
#define V2_FY 16
#elif OFB2_FFT_HEIGHT <= 32 && V2_H+2*V2_BORDER <= 32
#define V2_FY 32
#elif OFB2_FFT_HEIGHT <= 64 && V2_H+2*V2_BORDER <= 64
#define V2_FY 64
#elif OFB2_FFT_HEIGHT <= 128 && V2_H+2*V2_BORDER <= 128
#define V2_FY 128
#elif OFB2_FFT_HEIGHT <= 256 && V2_H+2*V2_BORDER <= 256
#define V2_FY 256
#elif OFB2_FFT_HEIGHT <= 512 && V2_H+2*V2_BORDER <= 512
#define V2_FY 512
#elif OFB2_FFT_HEIGHT <= 1024 && V2_H+2*V2_BORDER <= 1024
#define V2_FY 1024
#elif OFB2_FFT_HEIGHT <= 2048 && V2_H+2*V2_BORDER <= 2048
#define V2_FY 2048
#elif OFB2_FFT_HEIGHT <= 4096 && V2_H+2*V2_BORDER <= 4096
#define V2_FY 4096
#elif OFB2_FFT_HEIGHT <= 8192 && V2_H+2*V2_BORDER <= 8192
#define V2_FY 8192
#elif OFB2_FFT_HEIGHT <= 16384 && V2_H+2*V2_BORDER <= 16384
#define V2_FY 16384
#elif OFB2_FFT_HEIGHT <= 32768 && V2_H+2*V2_BORDER <= 32768
#define V2_FY 32768
#elif OFB2_FFT_HEIGHT <= 65536 && V2_H+2*V2_BORDER <= 65536
#define V2_FY 65536
#elif OFB2_FFT_HEIGHT <= 131072 && V2_H+2*V2_BORDER <= 131072
#define V2_FY 131072
#elif OFB2_FFT_HEIGHT <= 262144 && V2_H+2*V2_BORDER <= 262144
#define V2_FY 262144
#elif OFB2_FFT_HEIGHT <= 524288 && V2_H+2*V2_BORDER <= 524288
#define V2_FY 524288
#elif OFB2_FFT_HEIGHT <= 1048576 && V2_H+2*V2_BORDER <= 1048576
#define V2_FY 1048576
#elif OFB2_FFT_HEIGHT <= 2097152 && V2_H+2*V2_BORDER <= 2097152
#define V2_FY 2097152
#elif OFB2_FFT_HEIGHT <= 4194304 && V2_H+2*V2_BORDER <= 4194304
#define V2_FY 4194304
#elif OFB2_FFT_HEIGHT <= 8388608 && V2_H+2*V2_BORDER <= 8388608
#define V2_FY 8388608
#elif OFB2_FFT_HEIGHT <= 16777216 && V2_H+2*V2_BORDER <= 16777216
#define V2_FY 16777216
#elif OFB2_FFT_HEIGHT <= 33554432 && V2_H+2*V2_BORDER <= 33554432
#define V2_FY 33554432
#elif OFB2_FFT_HEIGHT <= 67108864 && V2_H+2*V2_BORDER <= 67108864
#define V2_FY 67108864
#elif OFB2_FFT_HEIGHT <= 134217728 && V2_H+2*V2_BORDER <= 134217728
#define V2_FY 134217728
#elif OFB2_FFT_HEIGHT <= 268435456 && V2_H+2*V2_BORDER <= 268435456
#define V2_FY 268435456
#elif OFB2_FFT_HEIGHT <= 536870912 && V2_H+2*V2_BORDER <= 536870912
#define V2_FY 536870912
#elif OFB2_FFT_HEIGHT <= 1073741824 && V2_H+2*V2_BORDER <= 1073741824
#define V2_FY 1073741824
#else
#error "FFT dimension cannot be represented by a signed 32-bit dimension."
#endif
#if (V2_FX & (V2_FX-1)) || (V2_FY & (V2_FY-1)) || V2_FX < V2_W+2*V2_BORDER || V2_FY < V2_H+2*V2_BORDER
#error "FFT dimensions must be powers of two large enough for the frame and full kernel padding. Use zero for automatic sizing."
#endif
static const float PI=3.141592653589793;
uniform float BloomIntensity < ui_category="Bloom"; ui_label="Bloom intensity"; ui_category_closed=false; ui_tooltip="Overall brightness of the glow added to the scene. Higher values make bloom stronger; 0 hides it."; ui_type="slider"; ui_min=0; ui_max=4;  > = 0.15;
uniform float Threshold < ui_category="Bloom"; ui_label="Threshold"; ui_tooltip="Minimum source brightness for bloom, measured in linear light after Highlight selection exposure and the highlight shoulder. Raise it to limit bloom to brighter lights."; ui_type="slider"; ui_min=0; ui_max=2;  > = 0.6;
uniform float SoftKnee < ui_category="Bloom"; ui_label="Soft knee"; ui_tooltip="How gradually lights start blooming near the threshold. 0 gives a sharp cutoff; higher values give a smoother transition. Has little effect when Threshold is 0."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0.5;
uniform bool PerChannelThreshold < ui_category="Bloom"; ui_label="Per-channel threshold"; ui_tooltip="Apply Threshold and Soft knee separately to red, green and blue. Independent cutoffs can shift hue; Threshold colour preservation restores the source ratios while keeping the extracted brightness.";  > = false;
uniform float3 BloomTint < ui_category="Bloom"; ui_label="Bloom tint"; ui_tooltip="Red, green and blue multipliers for the finished glow. (1, 1, 1) keeps its colour; increase or decrease a channel to tint it."; ui_type="slider"; ui_min=0; ui_max=2;  > = float3(1,1,1);
uniform float BloomSaturation < ui_category="Bloom"; ui_label="Bloom saturation"; ui_tooltip="Colour strength of the finished glow. 0 is greyscale, 1 keeps its original colours, and values above 1 exaggerate them."; ui_type="slider"; ui_min=0; ui_max=2;  > = 1;
uniform int BlendMode < ui_category="Bloom"; ui_label="Blend"; ui_tooltip="Additive adds glow directly. Screen reduces the addition near white. Energy redistribution removes some extracted light before spreading it into bloom."; ui_type="combo"; ui_items="Additive\0Screen\0Energy redistribution\0";  > = 0;
uniform int DebugView < ui_category="Bloom"; ui_label="View"; ui_tooltip="Composite shows the scene with bloom. Highlights shows extracted light. Bloom shows the finished glow. Aperture + kernel shows the lens opening and its light-spread pattern in square previews."; ui_type="combo"; ui_items="Composite\0Highlights\0Bloom\0Aperture + kernel\0";  > = 0;
uniform float ThresholdColourPreservation < ui_category="Highlight preparation"; ui_label="Threshold colour preservation"; ui_category_closed=true; ui_tooltip="Keeps the source colour when Per-channel threshold is on. 1 restores its RGB ratios at the extracted luminance; 0 gives the original independent-channel result. Intermediate values blend between them."; ui_type="slider"; ui_min=0; ui_max=1;  > = 1;
uniform float PreExposure < ui_category="Highlight preparation"; ui_label="Highlight selection exposure (stops)"; ui_tooltip="Adjusts brightness before highlight selection, in stops. +1 doubles the values and changes which lights cross Threshold. Use Convolution source exposure to brighten selected light without changing that selection."; ui_type="slider"; ui_min=-8; ui_max=8;  > = 0;
uniform float SourceExposure < ui_category="Highlight preparation"; ui_label="Convolution source exposure (stops)"; ui_tooltip="Scales extracted light before convolution, without changing the cutoff or its RGB ratios. +1 doubles all three channels and -1 halves them. The working texture stays unclamped; final SDR clipping can still wash out bright colours."; ui_type="slider"; ui_min=-8; ui_max=8;  > = 0;
uniform float HighlightCompression < ui_category="Highlight preparation"; ui_label="Highlight shoulder"; ui_tooltip="Reduces very bright source values before applying the threshold while keeping their colour ratios. 0 disables compression; higher values give a stronger shoulder and can reduce bloom energy."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform float MaximumSource < ui_category="Highlight preparation"; ui_label="Maximum source"; ui_tooltip="Peak source limit after selection exposure. Over-limit RGB values are scaled together to preserve their ratios. Limits extreme values before extraction; a higher limit permits stronger bright sources."; ui_type="slider"; ui_min=1; ui_max=1024;  > = 64;
uniform float AntiFirefly < ui_category="Highlight preparation"; ui_label="Isolated hot-pixel suppression"; ui_tooltip="Suppresses isolated bright pixels using their neighbours. 0 disables it; higher values reject more isolated light. Can also weaken legitimate tiny highlights."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform float TemporalSmoothing < ui_category="Highlight preparation"; ui_label="Highlight smoothing"; ui_tooltip="Blends extracted highlights with recent frames to reduce flicker. 0 responds immediately. Higher values smooth more but can leave trails; large changes are rejected."; ui_type="slider"; ui_min=0; ui_max=0.9;  > = 0;
uniform int BladeCount < ui_category="Aperture"; ui_label="Blade count"; ui_category_closed=true; ui_tooltip="Number of sides in the procedural lens opening. Changes the diffraction spike pattern; a very round opening makes blade shapes less visible."; ui_type="slider"; ui_min=3; ui_max=16;  > = 6;
uniform float BladeRotation < ui_category="Aperture"; ui_label="Blade rotation"; ui_tooltip="Rotates the lens opening in degrees. Also rotates the diffraction pattern produced by its edges."; ui_type="slider"; ui_min=-180; ui_max=180;  > = 0;
uniform float BladeRoundness < ui_category="Aperture"; ui_label="Blade roundness"; ui_tooltip="Curves the whole opening outline towards a circle. 0 uses the polygon with any Blade corner rounding; 1 gives a circle. Higher values usually soften blade-related diffraction."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0.15;
uniform float CornerRounding < ui_category="Aperture"; ui_label="Blade corner rounding"; ui_tooltip="Rounds the polygon tips while retaining straight sections of the blades. 0 keeps sharp corners. Separate from Blade roundness, which curves the whole outline; has no effect on a fully circular opening."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform float ApertureRadius < ui_category="Aperture"; ui_label="Aperture radius"; ui_tooltip="Opening radius relative to the aperture canvas. A smaller opening spreads diffraction farther and can make raw bloom dimmer."; ui_type="slider"; ui_min=0.05; ui_max=0.98;  > = 0.82;
uniform float ApertureAspect < ui_category="Aperture"; ui_label="Aperture aspect ratio"; ui_tooltip="Width-to-height ratio of the lens opening. 1 is equal width and height; above 1 widens it and reduces its height. This changes the generated optical pattern."; ui_type="slider"; ui_min=0.25; ui_max=4;  > = 1;
uniform float EdgeSoftness < ui_category="Aperture"; ui_label="Edge softness"; ui_tooltip="Softens the opening and support-spoke edges. Higher values reduce sharp diffraction. 0 still keeps the minimum edge smoothing needed for clean pixels."; ui_type="slider"; ui_min=0; ui_max=0.1;  > = 0.002;
uniform float Obstruction < ui_category="Aperture"; ui_label="Central obstruction"; ui_tooltip="Radius of the blocked centre, as a fraction of the opening radius. 0 leaves the centre clear; larger values change the surrounding rings and light spread."; ui_type="slider"; ui_min=0; ui_max=0.85;  > = 0;
uniform int StrutCount < ui_category="Aperture"; ui_label="Support strut count"; ui_tooltip="Number of support spokes blocking the opening. 0 removes them. Spokes create additional diffraction lines."; ui_type="slider"; ui_min=0; ui_max=12;  > = 0;
uniform float StrutWidth < ui_category="Aperture"; ui_label="Strut width"; ui_tooltip="Half-width of each blocked support spoke, relative to the opening radius. Larger values make thicker spokes. Only affects the pattern when Support strut count is above 0."; ui_type="slider"; ui_min=0; ui_max=0.1;  > = 0.012;
uniform float StrutRotation < ui_category="Aperture"; ui_label="Strut rotation"; ui_tooltip="Rotates the support spokes in degrees, independently of the aperture blades. Also changes the direction of their diffraction lines."; ui_type="slider"; ui_min=-180; ui_max=180;  > = 0;
uniform float CatEye < ui_category="Aperture"; ui_label="Cat-eye clipping"; ui_tooltip="Clips one side of the opening with a shifted circular rim, giving an approximate off-axis cat-eye shape. 0 leaves it clear. The same opening is used for every light in the frame; this is not a separate lens model for screen edges."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform float CatEyeAngle < ui_category="Aperture"; ui_label="Cat-eye direction"; ui_tooltip="Direction of the clipped side in degrees. 0 clips the right side of the aperture preview; 90 turns the clipping by a quarter rotation. Only affects the pattern when Cat-eye clipping is above 0."; ui_type="slider"; ui_min=-180; ui_max=180;  > = 0;
uniform float DustOpacity < ui_category="Aperture imperfections"; ui_label="Dust opacity"; ui_category_closed=true; ui_tooltip="How strongly procedural dust blocks light through the opening. 0 disables dust. Higher values make the specks darker and change the actual kernel, including its faint diffraction structure."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform float DustCoverage < ui_category="Aperture imperfections"; ui_label="Dust coverage"; ui_tooltip="Fraction of possible dust locations that contain a speck. Higher values add more dust at the selected size. Locations remain stable as coverage changes. Requires Dust opacity above 0."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0.35;
uniform float DustSize < ui_category="Aperture imperfections"; ui_label="Dust size (% of opening)"; ui_tooltip="Typical dust-speck diameter as a percentage of the opening diameter before aspect stretch. 1 means about one hundredth of the diameter. Specks vary in size and shape; very small dust needs enough aperture pixels to resolve."; ui_type="slider"; ui_min=0.05; ui_max=10;  > = 1.5;
uniform float ScratchOpacity < ui_category="Aperture imperfections"; ui_label="Scratch opacity"; ui_tooltip="How strongly scratches block light through the opening. 0 disables them. Scratches modify the real pupil FFT; they can add directional streaks roughly perpendicular to their length."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform int ScratchCount < ui_category="Aperture imperfections"; ui_label="Scratch count"; ui_tooltip="Number of randomly placed scratch segments. Some can fall outside the opening and be clipped. 0 removes them. More segments increase aperture rebuild work; requires Scratch opacity above 0."; ui_type="slider"; ui_min=0; ui_max=32;  > = 6;
uniform float ScratchWidth < ui_category="Aperture imperfections"; ui_label="Scratch width (% of opening)"; ui_tooltip="Typical full scratch width as a percentage of the opening diameter. Wider scratches block more light; very thin ones need enough aperture pixels to resolve."; ui_type="slider"; ui_min=0.02; ui_max=2;  > = 0.2;
uniform float ScratchLength < ui_category="Aperture imperfections"; ui_label="Scratch length (% of opening)"; ui_tooltip="Typical full scratch length as a percentage of the opening diameter. 100 spans one diameter before clipping; individual lengths vary. Longer scratches usually produce more directional structure."; ui_type="slider"; ui_min=1; ui_max=150;  > = 60;
uniform float ScratchAngle < ui_category="Aperture imperfections"; ui_label="Scratch direction"; ui_tooltip="Main scratch direction in degrees. 0 makes horizontal scratches in the aperture preview. Their diffraction streaks tend to run in the perpendicular direction."; ui_type="slider"; ui_min=-180; ui_max=180;  > = 0;
uniform float ScratchSpread < ui_category="Aperture imperfections"; ui_label="Scratch direction variation"; ui_tooltip="Random angle variation on either side of Scratch direction, in degrees. 0 aligns the scratches; higher values give more varied directions. The seed makes this variation repeatable."; ui_type="slider"; ui_min=0; ui_max=180;  > = 45;
uniform float TransmissionVariation < ui_category="Aperture imperfections"; ui_label="Uneven transmission"; ui_tooltip="Adds broad, smooth patches of lower light transmission, like an uneven coating or residue. 0 gives an even opening. Changes the real pupil and raw kernel energy; this is an appearance model rather than a calibrated dirty lens."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform float TransmissionSize < ui_category="Aperture imperfections"; ui_label="Transmission patch size (%)"; ui_tooltip="Size of smooth transmission patches as a percentage of the opening diameter. Higher values make broader patches; lower values make finer mottling. Requires Uneven transmission above 0."; ui_type="slider"; ui_min=2; ui_max=100;  > = 25;
uniform float Apodization < ui_category="Aperture imperfections"; ui_label="Radial transmission fade"; ui_tooltip="Gradually darkens the opening towards its rim, also called apodization. 0 disables it. Can soften diffraction rings and spread the core; reduces raw light throughput. Different from fading the generated kernel edges."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform float ApodizationFalloff < ui_category="Aperture imperfections"; ui_label="Radial fade curve"; ui_tooltip="Shape of Radial transmission fade. Lower values darken more of the opening; higher values concentrate the darkening near the rim. Only affects the pattern when Radial transmission fade is above 0."; ui_type="slider"; ui_min=0.5; ui_max=8;  > = 2;
uniform int ImperfectionSeed < ui_category="Aperture imperfections"; ui_label="Imperfection seed"; ui_tooltip="Repeatable layout for dust, scratches and transmission patches. Change it to generate another arrangement. It stays fixed between frames and affects neither the blade shape nor the scene highlights."; ui_type="slider"; ui_min=0; ui_max=65535;  > = 0;
uniform float Defocus < ui_category="Focus and aberrations"; ui_label="Defocus (signed waves)"; ui_category_closed=true; ui_tooltip="Moves the optics away from perfect focus. 0 is focused; larger positive or negative values spread highlights and reveal the aperture shape. The signs represent opposite sides of focus; units are wavelengths of phase error."; ui_type="slider"; ui_min=-8; ui_max=8;  > = 0;
uniform float Astigmatism < ui_category="Focus and aberrations"; ui_label="Astigmatism (waves)"; ui_tooltip="Makes focus differ between two directions, producing directional or stretched blur. 0 removes it; a larger absolute value strengthens it. Units are wavelengths of phase error."; ui_type="slider"; ui_min=-8; ui_max=8;  > = 0;
uniform float AstigmatismAngle < ui_category="Focus and aberrations"; ui_label="Astigmatism angle"; ui_tooltip="Rotates the directional focus blur in degrees. Only affects the pattern when Astigmatism is nonzero."; ui_type="slider"; ui_min=-180; ui_max=180;  > = 0;
uniform float Spherical < ui_category="Focus and aberrations"; ui_label="Spherical aberration"; ui_tooltip="Makes the centre and edges of the opening focus differently, changing the balance of the bright centre and surrounding rings. 0 removes this distortion; either sign gives a different focus shape."; ui_type="slider"; ui_min=-4; ui_max=4;  > = 0;
uniform float Coma < ui_category="Focus and aberrations"; ui_label="Coma"; ui_tooltip="Skews point lights into one-sided, comet-like shapes. 0 removes it; a larger absolute value makes the skew stronger. Changing the sign reverses its direction."; ui_type="slider"; ui_min=-4; ui_max=4;  > = 0;
uniform float ComaAngle < ui_category="Focus and aberrations"; ui_label="Coma angle"; ui_tooltip="Direction of the comet-like distortion, in degrees. Only affects the pattern when Coma is nonzero."; ui_type="slider"; ui_min=-180; ui_max=180;  > = 0;
uniform float Trefoil < ui_category="Focus and aberrations"; ui_label="Trefoil"; ui_tooltip="Adds a three-lobed distortion to the light-spread pattern. 0 removes it; a larger absolute value strengthens the shape."; ui_type="slider"; ui_min=-4; ui_max=4;  > = 0;
uniform float TrefoilAngle < ui_category="Focus and aberrations"; ui_label="Trefoil angle"; ui_tooltip="Rotates the three-lobed distortion in degrees. Only affects the pattern when Trefoil is nonzero."; ui_type="slider"; ui_min=-180; ui_max=180;  > = 0;
uniform float KernelScale < ui_category="Kernel and anamorphism"; ui_label="PSF scale (display pixels)"; ui_category_closed=true; ui_tooltip="1 uses native optical sampling: one aperture-FFT sample per display pixel before spectral scaling or anamorphism. Higher values enlarge and interpolate the pattern; lower values shrink it. Independent of the render divisor."; ui_type="slider"; ui_min=0.25; ui_max=32;  > = 1;
uniform float Anamorphism < ui_category="Kernel and anamorphism"; ui_label="Anamorphic stretch"; ui_tooltip="1 gives no extra stretch. Above 1 stretches the glow horizontally and squeezes it vertically; below 1 reverses this. Applied to the kernel independently of Aperture aspect ratio."; ui_type="slider"; ui_min=0.125; ui_max=8;  > = 1;
uniform float2 KernelStretch < ui_category="Kernel and anamorphism"; ui_label="Kernel stretch X / Y"; ui_tooltip="Separate horizontal (X) and vertical (Y) size multipliers for the glow. (1, 1) gives no extra stretch; 2 doubles that axis."; ui_type="slider"; ui_min=0.125; ui_max=8;  > = float2(1,1);
uniform float KernelRotation < ui_category="Kernel and anamorphism"; ui_label="Bloom rotation"; ui_tooltip="Rotates the finished light-spread pattern in degrees, after the aperture and optical effects are generated."; ui_type="slider"; ui_min=-180; ui_max=180;  > = 0;
uniform int Normalization < ui_category="Kernel and anamorphism"; ui_label="Kernel output"; ui_tooltip="Raw keeps the generated kernel brightness. Unit energy normalises the total of each colour channel; Unit peak normalises its brightest sample. These modes change brightness. PSF exposure is applied afterwards."; ui_type="combo"; ui_items="Raw / unnormalised\0Unit energy\0Unit peak\0";  > = 0;
uniform float KernelExposure < ui_category="Kernel and anamorphism"; ui_label="PSF exposure (stops)"; ui_tooltip="Brightness of the whole light-spread pattern, in stops. +1 doubles it and -1 halves it. Applied after Kernel output, independently of Bloom intensity."; ui_type="slider"; ui_min=-12; ui_max=12;  > = 0;
uniform float KernelEdgeFade < ui_category="Kernel and anamorphism"; ui_label="Kernel edge fade"; ui_tooltip="Width of the fade inward from the square kernel edges, as a fraction of its half-size. 0 keeps only the existing two-pixel edge taper; 1 fades from the centre to the edges. Changes the real kernel and its raw energy."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform float DiffractionStrength < ui_category="Diffraction"; ui_label="Diffraction strength"; ui_category_closed=true; ui_tooltip="Boosts spikes and other directional parts of the generated pattern. 0 removes this extra boost; the aperture still produces its natural diffraction."; ui_type="slider"; ui_min=0; ui_max=16;  > = 2;
uniform float DiffractionExposure < ui_category="Diffraction"; ui_label="Diffraction exposure (stops)"; ui_tooltip="Brightness of the extra diffraction boost, in stops. +1 doubles it and -1 halves it, without changing the centre sample. Requires Diffraction strength above 0."; ui_type="slider"; ui_min=-8; ui_max=16;  > = 2;
uniform float CoreIntensity < ui_category="Diffraction"; ui_label="Core intensity"; ui_tooltip="Brightness multiplier for the compact centre of the light-spread pattern. Raise it for a stronger central glow; the outer spread has its own Wing intensity."; ui_type="slider"; ui_min=0; ui_max=4;  > = 0.3;
uniform float WingIntensity < ui_category="Diffraction"; ui_label="Wing intensity"; ui_tooltip="Brightness multiplier for the outer light spread. Controls the base wings; the extra directional diffraction boost has separate controls."; ui_type="slider"; ui_min=0; ui_max=8;  > = 1;
uniform float WingLift < ui_category="Diffraction"; ui_label="Wing lift"; ui_tooltip="Raises very dim parts of the kernel to make faint tails more visible. 0 keeps the raw intensity response. Higher values can also increase the overall bloom energy."; ui_type="slider"; ui_min=0; ui_max=0.75;  > = 0;
uniform float SpectralDispersion < ui_category="Chromatic optics"; ui_label="Spectral dispersion"; ui_category_closed=true; ui_tooltip="Amount of wavelength-dependent spreading. 0 keeps the colours at the same diffraction scale; higher values separate them more and strengthen coloured fringes."; ui_type="slider"; ui_min=0; ui_max=4;  > = 1;
uniform float ChromaticFocus < ui_category="Chromatic optics"; ui_label="Chromatic focal shift"; ui_tooltip="Makes different colours focus differently. 0 adds no colour-dependent focus shift; larger positive or negative values strengthen it."; ui_type="slider"; ui_min=-4; ui_max=4;  > = 0;
uniform float FringeSuppression < ui_category="Chromatic optics"; ui_label="Chromatic fringe suppression"; ui_tooltip="Removes colour from the optical pattern. 0 keeps its spectral colours; 1 makes the kernel greyscale. The colour of the source lights still passes into the bloom."; ui_type="slider"; ui_min=0; ui_max=1;  > = 0;
uniform int InputSpace < ui_category="Colour space"; ui_label="Input colour space"; ui_category_closed=true; ui_tooltip="Match the colour encoding of the game frame: sRGB SDR for normal SDR, Linear / scRGB for linear values, or HDR10 PQ for PQ-encoded HDR. Bloom is calculated in linear light after decoding."; ui_type="combo"; ui_items="sRGB SDR\0Linear / scRGB\0HDR10 PQ\0";  > = 0;
uniform float ReferenceWhite < ui_category="Colour space"; ui_label="Reference white (nits)"; ui_tooltip="For HDR10 PQ, the brightness in nits represented by a linear value of 1. Increasing it makes the same HDR light smaller relative to Threshold. Ignored for sRGB and Linear / scRGB."; ui_type="slider"; ui_min=80; ui_max=1000;  > = 203;
uniform bool OutputClamp < ui_category="Colour space"; ui_label="Clamp SDR output"; ui_tooltip="Limits the final sRGB SDR output to the 0-1 range. Automatically ignored for Linear / scRGB and HDR10 PQ.";  > = true;
uniform float PreviewExposure < ui_category="Preview"; ui_label="Kernel preview exposure"; ui_category_closed=true; ui_tooltip="Brightness of the kernel preview only, in stops. +1 doubles it and -1 halves it. Does not change the generated kernel or bloom."; ui_type="slider"; ui_min=-12; ui_max=20;  > = 7;
uniform bool PreviewLog < ui_category="Preview"; ui_label="Log kernel preview"; ui_tooltip="Uses a logarithmic brightness display to reveal faint spikes and tails in the kernel preview. Preview only; does not change bloom.";  > = true;
uniform bool PreviewNative < ui_category="Preview"; ui_label="Display kernel at native pixel size"; ui_tooltip="Shows the optics at native display-pixel size: a 1025 kernel spans 1025 pixels at zoom 1. Larger previews are cropped. Turn off to fit the two square previews into the frame.";  > = true;
uniform float PreviewZoom < ui_category="Preview"; ui_label="Kernel preview zoom"; ui_tooltip="Magnification of both square optics previews. 1 uses the selected native or fitted size; 0.5 halves it and 2 doubles it. Preview only; oversized squares are cropped."; ui_type="slider"; ui_min=0.1; ui_max=8;  > = 1;
uniform int FrameCount < source="framecount"; >;
uniform float FrameTime < source="frametime"; >;
uniform bool ForceRebuild < source="key"; keycode=0x75; mode="press"; >;

texture2D ParamHistory { Width=14; Height=1; Format=RGBA32F; };
sampler2D ParamHistoryS { Texture=ParamHistory; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D ParamHistoryU { Texture=ParamHistory; };
texture2D CacheStatus { Width=1; Height=1; Format=RGBA32F; };
sampler2D CacheStatusS { Texture=CacheStatus; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D CacheStatusU { Texture=CacheStatus; };
texture2D CacheHistory { Width=1; Height=1; Format=RGBA32F; };
sampler2D CacheHistoryS { Texture=CacheHistory; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D CacheHistoryU { Texture=CacheHistory; };
texture2D CacheNext { Width=1; Height=1; Format=RGBA32F; };
sampler2D CacheNextS { Texture=CacheNext; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D CacheNextU { Texture=CacheNext; };
texture2D SourceStats { Width=1; Height=1; Format=RGBA32F; };
sampler2D SourceStatsS { Texture=SourceStats; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D SourceStatsU { Texture=SourceStats; };
texture2D Aperture { Width=V2_N; Height=V2_N; Format=RGBA32F; };
sampler2D ApertureS { Texture=Aperture; MinFilter=LINEAR; MagFilter=LINEAR; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D ApertureU { Texture=Aperture; };
texture3D PupilA { Width=V2_N; Height=V2_N; Depth=V2_WAVES; Format=RG32F; };
sampler3D PupilAS { Texture=PupilA; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; AddressW=CLAMP; };
storage3D PupilAU { Texture=PupilA; };
texture3D PupilB { Width=V2_N; Height=V2_N; Depth=V2_WAVES; Format=RG32F; };
sampler3D PupilBS { Texture=PupilB; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; AddressW=CLAMP; };
storage3D PupilBU { Texture=PupilB; };
texture3D PupilRows { Width=V2_N; Height=V2_N; Depth=V2_WAVES; Format=RG32F; };
sampler3D PupilRowsS { Texture=PupilRows; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; AddressW=CLAMP; };
storage3D PupilRowsU { Texture=PupilRows; };
texture3D OpticalPSF { Width=V2_N; Height=V2_N; Depth=V2_WAVES; Format=R32F; };
sampler3D OpticalPSFS { Texture=OpticalPSF; MinFilter=LINEAR; MagFilter=LINEAR; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; AddressW=CLAMP; };
storage3D OpticalPSFU { Texture=OpticalPSF; };
texture2D RawKernel { Width=V2_K; Height=V2_K; Format=RGBA32F; };
sampler2D RawKernelS { Texture=RawKernel; MinFilter=LINEAR; MagFilter=LINEAR; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D RawKernelU { Texture=RawKernel; };
texture2D KernelStats { Width=2; Height=1; Format=RGBA32F; };
sampler2D KernelStatsS { Texture=KernelStats; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D KernelStatsU { Texture=KernelStats; };
texture2D Source { Width=V2_W; Height=V2_H; Format=RGBA32F; };
sampler2D SourceS { Texture=Source; MinFilter=LINEAR; MagFilter=LINEAR; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D SourceU { Texture=Source; };
texture2D SourceHistory { Width=V2_W; Height=V2_H; Format=RGBA32F; };
sampler2D SourceHistoryS { Texture=SourceHistory; MinFilter=LINEAR; MagFilter=LINEAR; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D SourceHistoryU { Texture=SourceHistory; };
texture2D Bloom { Width=V2_W; Height=V2_H; Format=RGBA32F; };
sampler2D BloomS { Texture=Bloom; MinFilter=LINEAR; MagFilter=LINEAR; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D BloomU { Texture=Bloom; };
texture2D EnergyTiles { Width=(V2_W+15)/16; Height=(V2_H+15)/16; Format=RGBA32F; };
sampler2D EnergyTilesS { Texture=EnergyTiles; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D EnergyTilesU { Texture=EnergyTiles; };
texture2D WorkAR { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D WorkARS { Texture=WorkAR; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D WorkARU { Texture=WorkAR; };
texture2D WorkAG { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D WorkAGS { Texture=WorkAG; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D WorkAGU { Texture=WorkAG; };
texture2D WorkAB { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D WorkABS { Texture=WorkAB; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D WorkABU { Texture=WorkAB; };
texture2D WorkBR { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D WorkBRS { Texture=WorkBR; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D WorkBRU { Texture=WorkBR; };
texture2D WorkBG { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D WorkBGS { Texture=WorkBG; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D WorkBGU { Texture=WorkBG; };
texture2D WorkBB { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D WorkBBS { Texture=WorkBB; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D WorkBBU { Texture=WorkBB; };
texture2D RowTempR { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D RowTempRS { Texture=RowTempR; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D RowTempRU { Texture=RowTempR; };
texture2D RowTempG { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D RowTempGS { Texture=RowTempG; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D RowTempGU { Texture=RowTempG; };
texture2D RowTempB { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D RowTempBS { Texture=RowTempB; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D RowTempBU { Texture=RowTempB; };
texture2D TransferR { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D TransferRS { Texture=TransferR; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D TransferRU { Texture=TransferR; };
texture2D TransferG { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D TransferGS { Texture=TransferG; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D TransferGU { Texture=TransferG; };
texture2D TransferB { Width=V2_FX; Height=V2_FY; Format=RG32F; };
sampler2D TransferBS { Texture=TransferB; MinFilter=POINT; MagFilter=POINT; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
storage2D TransferBU { Texture=TransferB; };
texture2D GameColor : COLOR;
sampler2D GameS { Texture=GameColor; MinFilter=LINEAR; MagFilter=LINEAR; MipFilter=POINT; AddressU=CLAMP; AddressV=CLAMP; };
groupshared float2 FFTShared[1024];
groupshared float4 ReduceA[256];
groupshared float4 ReduceB[256];
float2 Cmul(float2 a,float2 b){return float2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);}
uint BitReverse(uint x,uint n){uint r=0;for(uint b=n;b>1;b>>=1){r=(r<<1)|(x&1);x>>=1;}return r;}
float2 Rotate(float2 p,float t){float s=sin(t),c=cos(t);return float2(c*p.x-s*p.y,s*p.x+c*p.y);}
// FXC's atan2(0,0) is undefined; guard the input before evaluating it.
float PolarAngle(float2 p){return atan2(p.y,any(p!=0)?p.x:1.0);}
float Lum(float3 v){return dot(v,float3(0.2126,0.7152,0.0722));}
float3 Saturation(float3 v,float s){return max(lerp(Lum(v).xxx,v,s),0);}
bool Dirty(){return tex2Dfetch(CacheStatusS,int2(0,0)).x>0.5;}
bool Empty(){return tex2Dfetch(SourceStatsS,int2(0,0)).y<=0.00000001;}

float4 OpticalParameters(int i){float4 v=0;switch(i){
case 0:v=float4(BladeCount,BladeRotation,BladeRoundness,CornerRounding);break;
case 1:v=float4(ApertureRadius,ApertureAspect,EdgeSoftness,Obstruction);break;
case 2:v=float4(StrutCount,StrutWidth,StrutRotation,CatEye);break;
case 3:v=float4(CatEyeAngle,DustOpacity,DustCoverage,DustSize);break;
case 4:v=float4(ScratchOpacity,ScratchCount,ScratchWidth,ScratchLength);break;
case 5:v=float4(ScratchAngle,ScratchSpread,TransmissionVariation,TransmissionSize);break;
case 6:v=float4(Apodization,ApodizationFalloff,ImperfectionSeed,Defocus);break;
case 7:v=float4(Astigmatism,AstigmatismAngle,Spherical,Coma);break;
case 8:v=float4(ComaAngle,Trefoil,TrefoilAngle,KernelScale);break;
case 9:v=float4(Anamorphism,KernelStretch.x,KernelStretch.y,KernelRotation);break;
case 10:v=float4(Normalization,KernelExposure,KernelEdgeFade,DiffractionStrength);break;
case 11:v=float4(DiffractionExposure,CoreIntensity,WingIntensity,WingLift);break;
case 12:v=float4(SpectralDispersion,ChromaticFocus,FringeSuppression,V2_N);break;
case 13:v=float4(V2_DIV,V2_FX,V2_FY,V2_WAVES);break;
}return v;}
[numthreads(1,1,1)]void CS_CacheState(uint3 id:SV_DispatchThreadID){
 float4 old=tex2Dfetch(CacheHistoryS,int2(0,0));
 bool valid=old.w==2023 && old.x==float(FrameCount-1);
 bool dirty=!valid||ForceRebuild;
 for(int i=0;i<14;++i)dirty=dirty||any(OpticalParameters(i)!=tex2Dfetch(ParamHistoryS,int2(i,0)));
 tex2Dstore(CacheStatusU,int2(0,0),float4(dirty?1:0,valid?1:0,0,old.z+(dirty?1:0)));
 tex2Dstore(CacheNextU,int2(0,0),float4(FrameCount,0,old.z+(dirty?1:0),2023));
}
[numthreads(1,1,1)]void CS_CacheCommit(uint3 id:SV_DispatchThreadID){
 if(Dirty())for(int i=0;i<14;++i)tex2Dstore(ParamHistoryU,int2(i,0),OpticalParameters(i));
 tex2Dstore(CacheHistoryU,int2(0,0),tex2Dfetch(CacheNextS,int2(0,0)));
}
// Transmission and low-order Zernike wavefront on a procedurally drawn pupil.
// Integer hashes keep imperfections stationary and repeatable without textures.
uint PupilHash(uint h){
 h^=h>>16;h*=2246822519u;h^=h>>13;h*=3266489917u;h^=h>>16;
 return h;
}
uint PupilCellHash(int2 cell,uint salt){
 return PupilHash(uint(cell.x)*1597334677u^uint(cell.y)*3812015801u^uint(ImperfectionSeed)*747796405u^salt);
}
float PupilRandom(uint h){return float(PupilHash(h)&16777215u)/16777216.0;}
float PupilNoise(float2 p){
 int2 cell=int2(floor(p));float2 f=frac(p);f=f*f*(3-2*f);
 float a=PupilRandom(PupilCellHash(cell,1831565813u));
 float b=PupilRandom(PupilCellHash(cell+int2(1,0),1831565813u));
 float c=PupilRandom(PupilCellHash(cell+int2(0,1),1831565813u));
 float d=PupilRandom(PupilCellHash(cell+int2(1,1),1831565813u));
 return lerp(lerp(a,b,f.x),lerp(c,d,f.x),f.y);
}
float ImperfectTransmission(float2 q){
 float transmission=1;
 float aa=0.5/(V2_N*max(ApertureRadius,0.0001));
 if(DustOpacity>0 && DustCoverage>0){
  float radius=max(DustSize*0.01,0.000001),cellSize=max(radius*4,aa*3);
  float2 grid=q/cellSize;int2 cell=int2(floor(grid));
  // At most nine nearby cells are needed regardless of particle density.
  for(int y=-1;y<=1;++y)for(int x=-1;x<=1;++x){
   int2 c=cell+int2(x,y);uint h=PupilCellHash(c,2891336453u);
   if(PupilRandom(h)>=saturate(DustCoverage))continue;
   float2 centre=(float2(c)+float2(PupilRandom(h+1u),PupilRandom(h+2u)))*cellSize;
   float2 d=Rotate(q-centre,PupilRandom(h+3u)*2*PI);
   float aspect=lerp(0.65,1.35,PupilRandom(h+4u));d.x/=aspect;
   float size=radius*lerp(0.55,1.25,PupilRandom(h+5u));
   float soft=max(aa,size*0.12);
   float mask=1-smoothstep(max(size-soft,0),size+soft,length(d));
   transmission*=1-saturate(DustOpacity)*mask;
  }
 }
 if(ScratchOpacity>0 && ScratchCount>0){
  [loop]for(int s=0;s<ScratchCount;++s){
   uint h=PupilHash(uint(s)*1597334677u^uint(ImperfectionSeed)*747796405u^277803737u);
   float2 centre=(float2(PupilRandom(h),PupilRandom(h+1u))*2-1)*1.15;
   float angle=radians(ScratchAngle+(PupilRandom(h+2u)*2-1)*ScratchSpread);
   float2 d=Rotate(q-centre,-angle);
   float halfLength=max(ScratchLength*0.01,0.000001)*lerp(0.45,1.0,PupilRandom(h+3u));
   float width=max(ScratchWidth*0.01,0.000001)*lerp(0.7,1.3,PupilRandom(h+4u));
   float distance=length(d-float2(clamp(d.x,-halfLength,halfLength),0));
   float soft=max(aa,width*0.2);
   float mask=1-smoothstep(max(width-soft,0),width+soft,distance);
   transmission*=1-saturate(ScratchOpacity)*mask;
  }
 }
 if(TransmissionVariation>0){
  float cellSize=max(TransmissionSize*0.02,0.000001);
  transmission*=1-saturate(TransmissionVariation)*PupilNoise(q/cellSize);
 }
 return saturate(transmission);
}
float4 PupilModel(float2 p){
 p/=float2(sqrt(max(ApertureAspect,0.0001)),rsqrt(max(ApertureAspect,0.0001)));
 float r=length(p)/max(ApertureRadius,0.0001),angle=PolarAngle(p);
 float sector=2*PI/max(BladeCount,3);
 float local=frac((angle-radians(BladeRotation))/sector+0.5)*sector-sector*0.5;
 float halfSector=PI/max(BladeCount,3),c=cos(halfSector),s=sin(halfSector);
 float bound=c/max(cos(local),0.0001);
 if(CornerRounding>0){
  // A smaller polygon plus circular caps preserves its straight blade sections.
  float rounded=saturate(CornerRounding),inner=1-rounded;
  float2 ray=float2(cos(abs(local)),sin(abs(local))),vertex=inner*float2(c,s);
  if(c*ray.y>inner*s*ray.x){
   float cross=ray.x*vertex.y-ray.y*vertex.x,cap=rounded*c;
   bound=dot(ray,vertex)+sqrt(max(cap*cap-cross*cross,0));
  }
 }
 bound=lerp(bound,1,saturate(BladeRoundness));
 float edge=max(EdgeSoftness,0.5/V2_N);
 float transmission=1-smoothstep(bound-edge,bound+edge,r);
 if(Obstruction>0)transmission*=smoothstep(Obstruction-edge,Obstruction+edge,r);
 for(int s=0;s<StrutCount;++s){
  float2 v=Rotate(p,-radians(StrutRotation)-2*PI*s/max(StrutCount,1));
  float cut=(1-smoothstep(StrutWidth-edge,StrutWidth+edge,abs(v.y)/max(ApertureRadius,0.0001)))*smoothstep(-edge,edge,v.x);
  transmission*=1-cut;
 }
 float2 q=p/max(ApertureRadius,0.0001);
 if(CatEye>0){
  float direction=radians(CatEyeAngle);
  float2 clipped=q+float2(cos(direction),sin(direction))*saturate(CatEye)*1.2;
  transmission*=1-smoothstep(1-edge,1+edge,length(clipped));
 }
 if(Apodization>0){
  float radial=saturate(r/max(bound,0.0001));
  transmission*=exp(-4*saturate(Apodization)*pow(radial,max(ApodizationFalloff,0.0001)));
 }
 if(transmission>0)transmission*=ImperfectTransmission(q);
 float r2=r*r,r3=r2*r,r4=r2*r2;
 float wave=Defocus*(2*r2-1)+Spherical*(6*r4-6*r2+1);
 wave+=Astigmatism*r2*cos(2*(angle-radians(AstigmatismAngle)));
 wave+=Coma*(3*r3-2*r)*cos(angle-radians(ComaAngle));
 wave+=Trefoil*r3*cos(3*(angle-radians(TrefoilAngle)));
 return float4(saturate(transmission),wave,r2,0);
}
[numthreads(8,8,1)]void CS_Aperture(uint3 id:SV_DispatchThreadID){
 if(!Dirty()||id.x>=V2_N||id.y>=V2_N)return;
 // Fixed 2x2 area sampling smooths procedural edges without another UI setting.
 float4 a=0;
 for(int y=0;y<2;++y)for(int x=0;x<2;++x){
  float4 v=PupilModel((float2(id.xy)+(float2(x,y)+0.5)*0.5)/V2_N*2-1);
  a+=float4(v.x,v.x*v.y,v.x*v.z,0);
 }
 a*=0.25;a.yz/=max(a.x,0.000000001);
 tex2Dstore(ApertureU,int2(id.xy),a);
}
float Lambda(uint slice){
 float lambda=550;
 #if V2_WAVES == 3
 lambda=slice==0?610:slice==1?550:460;
 #elif V2_WAVES == 1
 lambda=550;
 #else
 lambda=lerp(420.0,680.0,float(slice)/float(V2_WAVES-1));
 #endif
 return lambda;
}
float2 PupilAt(int2 p,uint slice){
 float4 aperture=tex2Dfetch(ApertureS,p);
 float wavelength=Lambda(slice),shift=(wavelength-550)/550;
 float wave=aperture.y*550/wavelength+ChromaticFocus*shift*(2*aperture.z-1);
 float phase=frac(wave)*2*PI;
 return aperture.x*float2(cos(phase),sin(phase));
}

float2 PupilARead(int2 p,uint c){return tex3Dfetch(PupilAS,int3(p,c)).xy;}
void PupilAWrite(int2 p,uint c,float2 v){tex3Dstore(PupilAU,int3(p,c),float4(v,0,0));}
float2 PupilBRead(int2 p,uint c){return tex3Dfetch(PupilBS,int3(p,c)).xy;}
void PupilBWrite(int2 p,uint c,float2 v){tex3Dstore(PupilBU,int3(p,c),float4(v,0,0));}
float2 PupilRowsRead(int2 p,uint c){return tex3Dfetch(PupilRowsS,int3(p,c)).xy;}
void PupilRowsWrite(int2 p,uint c,float2 v){tex3Dstore(PupilRowsU,int3(p,c),float4(v,0,0));}
float2 WorkARead(int2 p,uint c){float2 v=0;if(c==0)v=tex2Dfetch(WorkARS,p).xy;else if(c==1)v=tex2Dfetch(WorkAGS,p).xy;else v=tex2Dfetch(WorkABS,p).xy;return v;}
void WorkAWrite(int2 p,uint c,float2 v){if(c==0)tex2Dstore(WorkARU,p,float4(v,0,0));else if(c==1)tex2Dstore(WorkAGU,p,float4(v,0,0));else tex2Dstore(WorkABU,p,float4(v,0,0));}
float2 WorkBRead(int2 p,uint c){float2 v=0;if(c==0)v=tex2Dfetch(WorkBRS,p).xy;else if(c==1)v=tex2Dfetch(WorkBGS,p).xy;else v=tex2Dfetch(WorkBBS,p).xy;return v;}
void WorkBWrite(int2 p,uint c,float2 v){if(c==0)tex2Dstore(WorkBRU,p,float4(v,0,0));else if(c==1)tex2Dstore(WorkBGU,p,float4(v,0,0));else tex2Dstore(WorkBBU,p,float4(v,0,0));}
float2 RowTempRead(int2 p,uint c){float2 v=0;if(c==0)v=tex2Dfetch(RowTempRS,p).xy;else if(c==1)v=tex2Dfetch(RowTempGS,p).xy;else v=tex2Dfetch(RowTempBS,p).xy;return v;}
void RowTempWrite(int2 p,uint c,float2 v){if(c==0)tex2Dstore(RowTempRU,p,float4(v,0,0));else if(c==1)tex2Dstore(RowTempGU,p,float4(v,0,0));else tex2Dstore(RowTempBU,p,float4(v,0,0));}
float2 TransferRead(int2 p,uint c){float2 v=0;if(c==0)v=tex2Dfetch(TransferRS,p).xy;else if(c==1)v=tex2Dfetch(TransferGS,p).xy;else v=tex2Dfetch(TransferBS,p).xy;return v;}
void TransferWrite(int2 p,uint c,float2 v){if(c==0)tex2Dstore(TransferRU,p,float4(v,0,0));else if(c==1)tex2Dstore(TransferGU,p,float4(v,0,0));else tex2Dstore(TransferBU,p,float4(v,0,0));}
[numthreads(256,1,1)]void CS_PupilXLocal(uint3 gid:SV_GroupID,uint3 tid:SV_GroupThreadID){
 if(!(Dirty())||gid.z>=V2_WAVES)return;
 const uint N=V2_N,B=min(N,1024u);uint line=gid.y,base=gid.x*B;
 for(uint t=tid.x;t<B;t+=256){uint j=BitReverse(base+t,N);FFTShared[t]=PupilAt(int2(j,line),gid.z)/float(V2_N);}
 barrier();
 for(uint span=2;span<=B;span<<=1){
  for(uint b=tid.x;b<B/2;b+=256){uint k=b%(span/2),i=(b/(span/2))*span+k;
   float angle=-1*2*PI*float(k)/float(span);float2 x=FFTShared[i],y=Cmul(FFTShared[i+span/2],float2(cos(angle),sin(angle)));
   FFTShared[i]=x+y;FFTShared[i+span/2]=x-y;
  }barrier();
 }
 for(uint t=tid.x;t<B;t+=256){uint k=base+t;PupilAWrite(int2(k,line),gid.z,FFTShared[t]);}
}
#define Pupil_X_OUT PupilARead
#if V2_N >= 2048
[numthreads(256,1,1)]void CS_PupilX2048(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=2048;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 4096
[numthreads(256,1,1)]void CS_PupilX4096(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=4096;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
#if V2_N >= 8192
[numthreads(256,1,1)]void CS_PupilX8192(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=8192;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 16384
[numthreads(256,1,1)]void CS_PupilX16384(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=16384;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
#if V2_N >= 32768
[numthreads(256,1,1)]void CS_PupilX32768(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=32768;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 65536
[numthreads(256,1,1)]void CS_PupilX65536(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=65536;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
#if V2_N >= 131072
[numthreads(256,1,1)]void CS_PupilX131072(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=131072;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 262144
[numthreads(256,1,1)]void CS_PupilX262144(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=262144;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
#if V2_N >= 524288
[numthreads(256,1,1)]void CS_PupilX524288(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=524288;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 1048576
[numthreads(256,1,1)]void CS_PupilX1048576(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=1048576;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
#if V2_N >= 2097152
[numthreads(256,1,1)]void CS_PupilX2097152(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=2097152;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 4194304
[numthreads(256,1,1)]void CS_PupilX4194304(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=4194304;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
#if V2_N >= 8388608
[numthreads(256,1,1)]void CS_PupilX8388608(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=8388608;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 16777216
[numthreads(256,1,1)]void CS_PupilX16777216(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=16777216;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
#if V2_N >= 33554432
[numthreads(256,1,1)]void CS_PupilX33554432(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=33554432;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 67108864
[numthreads(256,1,1)]void CS_PupilX67108864(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=67108864;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
#if V2_N >= 134217728
[numthreads(256,1,1)]void CS_PupilX134217728(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=134217728;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 268435456
[numthreads(256,1,1)]void CS_PupilX268435456(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=268435456;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
#if V2_N >= 536870912
[numthreads(256,1,1)]void CS_PupilX536870912(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=536870912;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(i,line),id.z),y=Cmul(PupilARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(i,line),id.z,x+y);PupilBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilBRead
#endif
#if V2_N >= 1073741824
[numthreads(256,1,1)]void CS_PupilX1073741824(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=1073741824;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(i,line),id.z),y=Cmul(PupilBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(i,line),id.z,x+y);PupilAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Pupil_X_OUT
#define Pupil_X_OUT PupilARead
#endif
[numthreads(16,16,1)]void CS_PupilRowsCommit(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N||id.y>=V2_N)return;
 PupilRowsWrite(int2(id.xy),id.z,Pupil_X_OUT(int2(id.xy),id.z));
}
[numthreads(256,1,1)]void CS_PupilYLocal(uint3 gid:SV_GroupID,uint3 tid:SV_GroupThreadID){
 if(!(Dirty())||gid.z>=V2_WAVES)return;
 const uint N=V2_N,B=min(N,1024u);uint line=gid.y,base=gid.x*B;
 for(uint t=tid.x;t<B;t+=256){uint j=BitReverse(base+t,N);FFTShared[t]=PupilRowsRead(int2(line,j),gid.z)/float(V2_N);}
 barrier();
 for(uint span=2;span<=B;span<<=1){
  for(uint b=tid.x;b<B/2;b+=256){uint k=b%(span/2),i=(b/(span/2))*span+k;
   float angle=-1*2*PI*float(k)/float(span);float2 x=FFTShared[i],y=Cmul(FFTShared[i+span/2],float2(cos(angle),sin(angle)));
   FFTShared[i]=x+y;FFTShared[i+span/2]=x-y;
  }barrier();
 }
 for(uint t=tid.x;t<B;t+=256){uint k=base+t;PupilAWrite(int2(line,k),gid.z,FFTShared[t]);}
}
#define Pupil_Y_OUT PupilARead
#if V2_N >= 2048
[numthreads(256,1,1)]void CS_PupilY2048(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=2048;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 4096
[numthreads(256,1,1)]void CS_PupilY4096(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=4096;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
#if V2_N >= 8192
[numthreads(256,1,1)]void CS_PupilY8192(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=8192;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 16384
[numthreads(256,1,1)]void CS_PupilY16384(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=16384;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
#if V2_N >= 32768
[numthreads(256,1,1)]void CS_PupilY32768(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=32768;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 65536
[numthreads(256,1,1)]void CS_PupilY65536(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=65536;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
#if V2_N >= 131072
[numthreads(256,1,1)]void CS_PupilY131072(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=131072;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 262144
[numthreads(256,1,1)]void CS_PupilY262144(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=262144;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
#if V2_N >= 524288
[numthreads(256,1,1)]void CS_PupilY524288(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=524288;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 1048576
[numthreads(256,1,1)]void CS_PupilY1048576(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=1048576;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
#if V2_N >= 2097152
[numthreads(256,1,1)]void CS_PupilY2097152(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=2097152;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 4194304
[numthreads(256,1,1)]void CS_PupilY4194304(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=4194304;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
#if V2_N >= 8388608
[numthreads(256,1,1)]void CS_PupilY8388608(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=8388608;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 16777216
[numthreads(256,1,1)]void CS_PupilY16777216(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=16777216;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
#if V2_N >= 33554432
[numthreads(256,1,1)]void CS_PupilY33554432(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=33554432;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 67108864
[numthreads(256,1,1)]void CS_PupilY67108864(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=67108864;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
#if V2_N >= 134217728
[numthreads(256,1,1)]void CS_PupilY134217728(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=134217728;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 268435456
[numthreads(256,1,1)]void CS_PupilY268435456(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=268435456;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
#if V2_N >= 536870912
[numthreads(256,1,1)]void CS_PupilY536870912(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=536870912;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilARead(int2(line,i),id.z),y=Cmul(PupilARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilBWrite(int2(line,i),id.z,x+y);PupilBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilBRead
#endif
#if V2_N >= 1073741824
[numthreads(256,1,1)]void CS_PupilY1073741824(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_N/2||id.y>=V2_N)return;
 const uint span=1073741824;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=PupilBRead(int2(line,i),id.z),y=Cmul(PupilBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 PupilAWrite(int2(line,i),id.z,x+y);PupilAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Pupil_Y_OUT
#define Pupil_Y_OUT PupilARead
#endif
[numthreads(8,8,1)]void CS_OpticalIntensity(uint3 id:SV_DispatchThreadID){
 if(!Dirty()||id.x>=V2_N||id.y>=V2_N||id.z>=V2_WAVES)return;
 int2 p=(int2(id.xy)+V2_N/2)%V2_N;
 float2 a=Pupil_Y_OUT(p,id.z);
 // The forward FFT uses 1/N per axis. No measured energy/peak normalization.
 tex3Dstore(OpticalPSFU,int3(id),dot(a,a).xxxx);
}
float SlicePSF(float2 q,uint s){
 float2 p=q+V2_N*0.5;
 float value=0;
 if(all(abs(q)<=V2_N*0.5)){
  // Wrap the Nyquist endpoint to obtain an odd, inclusive centred canvas.
  int2 b=int2(floor(p));float2 f=frac(p);
  int2 a=b%V2_N,c=(b+1)%V2_N;
  float l=lerp(tex3Dfetch(OpticalPSFS,int3(a,s)).r,tex3Dfetch(OpticalPSFS,int3(c.x,a.y,s)).r,f.x);
  float h=lerp(tex3Dfetch(OpticalPSFS,int3(a.x,c.y,s)).r,tex3Dfetch(OpticalPSFS,int3(c,s)).r,f.x);
  value=lerp(l,h,f.y);
 }
 return max(value,0);
}
float3 SpectralPSF(float2 q){
 float3 value=0;
 #if V2_WAVES == 3
 for(uint s=0;s<3;++s){
  float stretch=pow(max(Lambda(s)/550,0.0001),max(SpectralDispersion,0));
  value[s]=SlicePSF(q/max(stretch,0.0001),s)/(stretch*stretch);
 }
 #else
 float3 weights=0;
 [loop]for(uint s=0;s<V2_WAVES;++s){
  float wavelength=Lambda(s);
  float3 deviation=(wavelength-float3(610,545,455))/float3(48,36,30);
  float3 response=exp(-0.5*deviation*deviation);
  float stretch=pow(max(wavelength/550,0.0001),max(SpectralDispersion,0));
  value+=response*SlicePSF(q/max(stretch,0.0001),s)/(stretch*stretch);
  weights+=response;
 }
 value/=max(weights,0.00000001);
 #endif
 return lerp(value,Lum(value).xxx,saturate(FringeSuppression));
}
float3 ShapeKernel(float2 display){
 float2 p=Rotate(display,-radians(KernelRotation));
 p/=max(KernelStretch,0.0001)*float2(max(Anamorphism,0.0001),1/max(Anamorphism,0.0001));
 float2 q=p/max(KernelScale,0.0001);
 float3 base=SpectralPSF(q);
 float3 angular=(SpectralPSF(Rotate(q,0.15))+SpectralPSF(Rotate(q,-0.15))+SpectralPSF(Rotate(q,0.3))+SpectralPSF(Rotate(q,-0.3)))*0.25;
 float3 directional=max(base-angular,0);
 float distance2=dot(q,q);
 float core=exp(-0.5*distance2);
 float3 value=base*lerp(WingIntensity,CoreIntensity,core);
 value+=directional*DiffractionStrength*exp2(DiffractionExposure)*(1-core);
 value=pow(max(value,0),max(1-WingLift,0.05));
 // Square edge fade. Keep the two-pixel base taper for clean pixel integration.
 float edge=max(abs(display.x),abs(display.y));
 float fadeWidth=max(2,V2_N*0.5*saturate(KernelEdgeFade));
 value*=1-smoothstep(max(V2_N*0.5-fadeWidth,0),V2_N*0.5,edge);
 return value;
}
[numthreads(8,8,1)]void CS_RawKernel(uint3 id:SV_DispatchThreadID){
 if(!Dirty()||id.x>=V2_K||id.y>=V2_K)return;
 // K=N+1 is odd: texel (N/2,N/2) has UV exactly (0.5,0.5).
 float2 display=float2(id.xy)-V2_N*0.5;
 tex2Dstore(RawKernelU,int2(id.xy),float4(ShapeKernel(display),1));
}
[numthreads(256,1,1)]void CS_KernelStatistics(uint3 tid:SV_GroupThreadID){
 if(!Dirty())return;
 float4 sum=0,peak=0;
 for(uint i=tid.x;i<V2_K*V2_K;i+=256){
  float4 v=tex2Dfetch(RawKernelS,int2(i%V2_K,i/V2_K));sum+=v;peak=max(peak,v);
 }
 ReduceA[tid.x]=sum;ReduceB[tid.x]=peak;barrier();
 for(uint s=128;s>0;s>>=1){
  if(tid.x<s){ReduceA[tid.x]+=ReduceA[tid.x+s];ReduceB[tid.x]=max(ReduceB[tid.x],ReduceB[tid.x+s]);}barrier();
 }
 if(tid.x==0){tex2Dstore(KernelStatsU,int2(0,0),ReduceA[0]);tex2Dstore(KernelStatsU,int2(1,0),ReduceB[0]);}
}
float3 NativeKernel(float2 display){
 float3 value=0;
 if(all(abs(display)<=V2_N*0.5)){
  // Half-texel offset is relative to the ODD K, not the aperture's even N.
  float2 uv=(display+V2_N*0.5+0.5)/V2_K;
  value=tex2Dlod(RawKernelS,float4(uv,0,0)).rgb;
 }
 return value;
}
float2 EmbeddedRead(int2 pos,uint channel){
 int2 d=pos;
 if(d.x>V2_FX/2)d.x-=V2_FX;
 if(d.y>V2_FY/2)d.y-=V2_FY;
 float3 value=0;
 if(all(abs(d)<=V2_BORDER)){
  // Integrate the native kernel over the processing texel footprint. This
  // preserves support in DISPLAY pixels and captures narrow PSF cores at 1/8.
  for(int y=0;y<V2_DIV;++y)for(int x=0;x<V2_DIV;++x){
   float2 display=float2(d*V2_DIV)+float2(x,y)+0.5-V2_DIV*0.5;
   value+=NativeKernel(display);
  }
 }
 if(Normalization==1)value/=max(tex2Dfetch(KernelStatsS,int2(0,0)).rgb,0.0000000001);
 else if(Normalization==2)value/=max(tex2Dfetch(KernelStatsS,int2(1,0)).rgb,0.0000000001);
 value*=exp2(KernelExposure);
 return float2(value[channel],0);
}

float3 Decode(float3 v){
 if(InputSpace!=1)v=max(v,0);
 if(InputSpace==0)v=lerp(v/12.92,pow(max((v+0.055)/1.055,0),2.4),step(0.04045,v));
 else if(InputSpace==2){
  float3 p=pow(max(v,0),1.0/78.84375);
  v=10000*pow(max(p-0.8359375,0)/max(18.8515625-18.6875*p,0.00000001),1.0/0.1593017578125)/max(ReferenceWhite,0.01);
 }
 return v;
}
float3 Encode(float3 v){
 if(InputSpace!=1)v=max(v,0);
 if(InputSpace==0)v=lerp(v*12.92,1.055*pow(max(v,0),1.0/2.4)-0.055,step(0.0031308,v));
 else if(InputSpace==2){
  float3 p=pow(max(v*max(ReferenceWhite,0.01)/10000,0),0.1593017578125);
  v=pow((0.8359375+18.8515625*p)/(1+18.6875*p),78.84375);
 }
 return v;
}
float3 ExtractLight(float3 v){
 v=max(v,0)*exp2(PreExposure);
 float peak=max(v.r,max(v.g,v.b));
 v*=min(1,max(MaximumSource,0)/max(peak,0.00000001));
 float brightness=max(v.r,max(v.g,v.b));
 float compressed=lerp(brightness,brightness/(1+brightness),saturate(HighlightCompression));
 v*=compressed/max(brightness,0.00000001);brightness=compressed;
 float threshold=max(Threshold,0),knee=max(threshold*SoftKnee,0.000001);
 float soft=clamp(brightness-threshold+knee,0,2*knee);soft=soft*soft/(4*knee);
 float contribution=max(brightness-threshold,soft)/max(brightness,0.00000001);
 float3 result=v*contribution;
 if(PerChannelThreshold){
  float3 channelSoft=clamp(v-threshold+knee,0,2*knee);channelSoft=channelSoft*channelSoft/(4*knee);
  float3 channelContribution=max(v-threshold,channelSoft)/max(v,0.00000001);
  result=v*channelContribution;
  float3 preserved=v*(Lum(result)/max(Lum(v),0.00000001));
  result=lerp(result,preserved,saturate(ThresholdColourPreservation));
 }
 return result;
}
float3 SourceAt(int2 display){
 float2 uv=(clamp(display,int2(0,0),int2(BUFFER_WIDTH-1,BUFFER_HEIGHT-1))+0.5)/float2(BUFFER_WIDTH,BUFFER_HEIGHT);
 float3 v=Decode(tex2Dlod(GameS,float4(uv,0,0)).rgb);
 if(AntiFirefly>0){
  float2 px=1.0/float2(BUFFER_WIDTH,BUFFER_HEIGHT);
  float3 n=max(max(Decode(tex2Dlod(GameS,float4(uv+float2(px.x,0),0,0)).rgb),Decode(tex2Dlod(GameS,float4(uv-float2(px.x,0),0,0)).rgb)),
               max(Decode(tex2Dlod(GameS,float4(uv+float2(0,px.y),0,0)).rgb),Decode(tex2Dlod(GameS,float4(uv-float2(0,px.y),0,0)).rgb)));
  float cap=max(max(n.r,max(n.g,n.b))*8,0.00000001);
  float bright=max(v.r,max(v.g,v.b));v*=lerp(1,min(1,cap/max(bright,0.00000001)),saturate(AntiFirefly));
 }
 return ExtractLight(v)*exp2(SourceExposure);
}
[numthreads(16,16,1)]void CS_Extract(uint3 id:SV_DispatchThreadID,uint3 gid:SV_GroupID,uint3 tid:SV_GroupThreadID){
 uint index=tid.y*16+tid.x;float3 value=0;
 if(id.x<V2_W&&id.y<V2_H){
  // Threshold BEFORE area averaging: tiny bright sources survive downsampling.
  int count=0;
  for(int y=0;y<V2_DIV;++y)for(int x=0;x<V2_DIV;++x){
   int2 p=int2(id.xy)*V2_DIV+int2(x,y);
   if(p.x<BUFFER_WIDTH&&p.y<BUFFER_HEIGHT){value+=SourceAt(p);++count;}
  }
  value/=max(count,1);
  if(TemporalSmoothing>0&&tex2Dfetch(CacheStatusS,int2(0,0)).y>0.5){
   float3 old=tex2Dfetch(SourceHistoryS,int2(id.xy)).rgb;
   float delta=abs(Lum(value)-Lum(old))/max(max(Lum(value),Lum(old)),0.00000001);
   float weight=TemporalSmoothing*(1-smoothstep(0.1,0.4,delta));
   if(Lum(value)<Lum(old))weight*=0.25;
   value=lerp(value,old,weight);
  }
  tex2Dstore(SourceU,int2(id.xy),float4(value,1));
 }
 ReduceA[index]=float4(Lum(value),max(value.r,max(value.g,value.b)),0,0);barrier();
 for(uint s=128;s>0;s>>=1){if(index<s){ReduceA[index].x+=ReduceA[index+s].x;ReduceA[index].y=max(ReduceA[index].y,ReduceA[index+s].y);}barrier();}
 if(index==0)tex2Dstore(EnergyTilesU,int2(gid.xy),ReduceA[0]);
}
[numthreads(256,1,1)]void CS_SourceStatistics(uint3 tid:SV_GroupThreadID){
 const uint W=(V2_W+15)/16,H=(V2_H+15)/16;float4 value=0;
 for(uint i=tid.x;i<W*H;i+=256){float4 v=tex2Dfetch(EnergyTilesS,int2(i%W,i/W));value.x+=v.x;value.y=max(value.y,v.y);}
 ReduceA[tid.x]=value;barrier();
 for(uint s=128;s>0;s>>=1){if(tid.x<s){ReduceA[tid.x].x+=ReduceA[tid.x+s].x;ReduceA[tid.x].y=max(ReduceA[tid.x].y,ReduceA[tid.x+s].y);}barrier();}
 if(tid.x==0)tex2Dstore(SourceStatsU,int2(0,0),ReduceA[0]);
}
float2 SourceRead(int2 p,uint channel){
 int2 q=p-V2_BORDER;float value=0;
 if(all(q>=0)&&q.x<V2_W&&q.y<V2_H)value=tex2Dfetch(SourceS,q)[channel];
 return float2(value,0);
}

[numthreads(256,1,1)]void CS_KernelXLocal(uint3 gid:SV_GroupID,uint3 tid:SV_GroupThreadID){
 if(!(Dirty()))return;
 const uint N=V2_FX,B=min(N,1024u);uint line=gid.y,base=gid.x*B;
 for(uint t=tid.x;t<B;t+=256){uint j=BitReverse(base+t,N);FFTShared[t]=EmbeddedRead(int2(j,line),gid.z);}
 barrier();
 for(uint span=2;span<=B;span<<=1){
  for(uint b=tid.x;b<B/2;b+=256){uint k=b%(span/2),i=(b/(span/2))*span+k;
   float angle=-1*2*PI*float(k)/float(span);float2 x=FFTShared[i],y=Cmul(FFTShared[i+span/2],float2(cos(angle),sin(angle)));
   FFTShared[i]=x+y;FFTShared[i+span/2]=x-y;
  }barrier();
 }
 for(uint t=tid.x;t<B;t+=256){uint k=base+t;WorkAWrite(int2(k,line),gid.z,FFTShared[t]);}
}
#define Kernel_X_OUT WorkARead
#if V2_FX >= 2048
[numthreads(256,1,1)]void CS_KernelX2048(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=2048;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 4096
[numthreads(256,1,1)]void CS_KernelX4096(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=4096;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
#if V2_FX >= 8192
[numthreads(256,1,1)]void CS_KernelX8192(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=8192;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 16384
[numthreads(256,1,1)]void CS_KernelX16384(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=16384;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
#if V2_FX >= 32768
[numthreads(256,1,1)]void CS_KernelX32768(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=32768;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 65536
[numthreads(256,1,1)]void CS_KernelX65536(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=65536;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
#if V2_FX >= 131072
[numthreads(256,1,1)]void CS_KernelX131072(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=131072;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 262144
[numthreads(256,1,1)]void CS_KernelX262144(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=262144;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
#if V2_FX >= 524288
[numthreads(256,1,1)]void CS_KernelX524288(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=524288;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 1048576
[numthreads(256,1,1)]void CS_KernelX1048576(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=1048576;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
#if V2_FX >= 2097152
[numthreads(256,1,1)]void CS_KernelX2097152(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=2097152;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 4194304
[numthreads(256,1,1)]void CS_KernelX4194304(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=4194304;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
#if V2_FX >= 8388608
[numthreads(256,1,1)]void CS_KernelX8388608(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=8388608;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 16777216
[numthreads(256,1,1)]void CS_KernelX16777216(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=16777216;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
#if V2_FX >= 33554432
[numthreads(256,1,1)]void CS_KernelX33554432(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=33554432;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 67108864
[numthreads(256,1,1)]void CS_KernelX67108864(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=67108864;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
#if V2_FX >= 134217728
[numthreads(256,1,1)]void CS_KernelX134217728(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=134217728;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 268435456
[numthreads(256,1,1)]void CS_KernelX268435456(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=268435456;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
#if V2_FX >= 536870912
[numthreads(256,1,1)]void CS_KernelX536870912(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=536870912;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkBRead
#endif
#if V2_FX >= 1073741824
[numthreads(256,1,1)]void CS_KernelX1073741824(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=1073741824;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Kernel_X_OUT
#define Kernel_X_OUT WorkARead
#endif
[numthreads(16,16,1)]void CS_KernelRowsCommit(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FX||id.y>=V2_FY)return;
 RowTempWrite(int2(id.xy),id.z,Kernel_X_OUT(int2(id.xy),id.z));
}
[numthreads(256,1,1)]void CS_KernelYLocal(uint3 gid:SV_GroupID,uint3 tid:SV_GroupThreadID){
 if(!(Dirty()))return;
 const uint N=V2_FY,B=min(N,1024u);uint line=gid.y,base=gid.x*B;
 for(uint t=tid.x;t<B;t+=256){uint j=BitReverse(base+t,N);FFTShared[t]=RowTempRead(int2(line,j),gid.z);}
 barrier();
 for(uint span=2;span<=B;span<<=1){
  for(uint b=tid.x;b<B/2;b+=256){uint k=b%(span/2),i=(b/(span/2))*span+k;
   float angle=-1*2*PI*float(k)/float(span);float2 x=FFTShared[i],y=Cmul(FFTShared[i+span/2],float2(cos(angle),sin(angle)));
   FFTShared[i]=x+y;FFTShared[i+span/2]=x-y;
  }barrier();
 }
 for(uint t=tid.x;t<B;t+=256){uint k=base+t;WorkAWrite(int2(line,k),gid.z,FFTShared[t]);}
}
#define Kernel_Y_OUT WorkARead
#if V2_FY >= 2048
[numthreads(256,1,1)]void CS_KernelY2048(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=2048;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 4096
[numthreads(256,1,1)]void CS_KernelY4096(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=4096;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
#if V2_FY >= 8192
[numthreads(256,1,1)]void CS_KernelY8192(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=8192;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 16384
[numthreads(256,1,1)]void CS_KernelY16384(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=16384;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
#if V2_FY >= 32768
[numthreads(256,1,1)]void CS_KernelY32768(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=32768;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 65536
[numthreads(256,1,1)]void CS_KernelY65536(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=65536;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
#if V2_FY >= 131072
[numthreads(256,1,1)]void CS_KernelY131072(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=131072;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 262144
[numthreads(256,1,1)]void CS_KernelY262144(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=262144;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
#if V2_FY >= 524288
[numthreads(256,1,1)]void CS_KernelY524288(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=524288;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 1048576
[numthreads(256,1,1)]void CS_KernelY1048576(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=1048576;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
#if V2_FY >= 2097152
[numthreads(256,1,1)]void CS_KernelY2097152(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=2097152;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 4194304
[numthreads(256,1,1)]void CS_KernelY4194304(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=4194304;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
#if V2_FY >= 8388608
[numthreads(256,1,1)]void CS_KernelY8388608(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=8388608;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 16777216
[numthreads(256,1,1)]void CS_KernelY16777216(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=16777216;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
#if V2_FY >= 33554432
[numthreads(256,1,1)]void CS_KernelY33554432(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=33554432;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 67108864
[numthreads(256,1,1)]void CS_KernelY67108864(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=67108864;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
#if V2_FY >= 134217728
[numthreads(256,1,1)]void CS_KernelY134217728(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=134217728;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 268435456
[numthreads(256,1,1)]void CS_KernelY268435456(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=268435456;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
#if V2_FY >= 536870912
[numthreads(256,1,1)]void CS_KernelY536870912(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=536870912;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkBRead
#endif
#if V2_FY >= 1073741824
[numthreads(256,1,1)]void CS_KernelY1073741824(uint3 id:SV_DispatchThreadID){
 if(!(Dirty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=1073741824;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Kernel_Y_OUT
#define Kernel_Y_OUT WorkARead
#endif
[numthreads(16,16,1)]void CS_KernelCommit(uint3 id:SV_DispatchThreadID){
 if(!Dirty()||id.x>=V2_FX||id.y>=V2_FY)return;
 TransferWrite(int2(id.xy),id.z,Kernel_Y_OUT(int2(id.xy),id.z));
}
[numthreads(256,1,1)]void CS_SceneXLocal(uint3 gid:SV_GroupID,uint3 tid:SV_GroupThreadID){
 if(!(!Empty()))return;
 const uint N=V2_FX,B=min(N,1024u);uint line=gid.y,base=gid.x*B;
 for(uint t=tid.x;t<B;t+=256){uint j=BitReverse(base+t,N);FFTShared[t]=SourceRead(int2(j,line),gid.z)/float(V2_FX);}
 barrier();
 for(uint span=2;span<=B;span<<=1){
  for(uint b=tid.x;b<B/2;b+=256){uint k=b%(span/2),i=(b/(span/2))*span+k;
   float angle=-1*2*PI*float(k)/float(span);float2 x=FFTShared[i],y=Cmul(FFTShared[i+span/2],float2(cos(angle),sin(angle)));
   FFTShared[i]=x+y;FFTShared[i+span/2]=x-y;
  }barrier();
 }
 for(uint t=tid.x;t<B;t+=256){uint k=base+t;WorkAWrite(int2(k,line),gid.z,FFTShared[t]);}
}
#define Scene_X_OUT WorkARead
#if V2_FX >= 2048
[numthreads(256,1,1)]void CS_SceneX2048(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=2048;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 4096
[numthreads(256,1,1)]void CS_SceneX4096(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=4096;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
#if V2_FX >= 8192
[numthreads(256,1,1)]void CS_SceneX8192(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=8192;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 16384
[numthreads(256,1,1)]void CS_SceneX16384(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=16384;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
#if V2_FX >= 32768
[numthreads(256,1,1)]void CS_SceneX32768(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=32768;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 65536
[numthreads(256,1,1)]void CS_SceneX65536(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=65536;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
#if V2_FX >= 131072
[numthreads(256,1,1)]void CS_SceneX131072(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=131072;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 262144
[numthreads(256,1,1)]void CS_SceneX262144(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=262144;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
#if V2_FX >= 524288
[numthreads(256,1,1)]void CS_SceneX524288(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=524288;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 1048576
[numthreads(256,1,1)]void CS_SceneX1048576(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=1048576;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
#if V2_FX >= 2097152
[numthreads(256,1,1)]void CS_SceneX2097152(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=2097152;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 4194304
[numthreads(256,1,1)]void CS_SceneX4194304(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=4194304;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
#if V2_FX >= 8388608
[numthreads(256,1,1)]void CS_SceneX8388608(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=8388608;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 16777216
[numthreads(256,1,1)]void CS_SceneX16777216(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=16777216;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
#if V2_FX >= 33554432
[numthreads(256,1,1)]void CS_SceneX33554432(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=33554432;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 67108864
[numthreads(256,1,1)]void CS_SceneX67108864(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=67108864;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
#if V2_FX >= 134217728
[numthreads(256,1,1)]void CS_SceneX134217728(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=134217728;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 268435456
[numthreads(256,1,1)]void CS_SceneX268435456(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=268435456;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
#if V2_FX >= 536870912
[numthreads(256,1,1)]void CS_SceneX536870912(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=536870912;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkBRead
#endif
#if V2_FX >= 1073741824
[numthreads(256,1,1)]void CS_SceneX1073741824(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=1073741824;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Scene_X_OUT
#define Scene_X_OUT WorkARead
#endif
[numthreads(16,16,1)]void CS_SceneRowsCommit(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX||id.y>=V2_FY)return;
 RowTempWrite(int2(id.xy),id.z,Scene_X_OUT(int2(id.xy),id.z));
}
[numthreads(256,1,1)]void CS_SceneYLocal(uint3 gid:SV_GroupID,uint3 tid:SV_GroupThreadID){
 if(!(!Empty()))return;
 const uint N=V2_FY,B=min(N,1024u);uint line=gid.y,base=gid.x*B;
 for(uint t=tid.x;t<B;t+=256){uint j=BitReverse(base+t,N);FFTShared[t]=RowTempRead(int2(line,j),gid.z)/float(V2_FY);}
 barrier();
 for(uint span=2;span<=B;span<<=1){
  for(uint b=tid.x;b<B/2;b+=256){uint k=b%(span/2),i=(b/(span/2))*span+k;
   float angle=-1*2*PI*float(k)/float(span);float2 x=FFTShared[i],y=Cmul(FFTShared[i+span/2],float2(cos(angle),sin(angle)));
   FFTShared[i]=x+y;FFTShared[i+span/2]=x-y;
  }barrier();
 }
 for(uint t=tid.x;t<B;t+=256){uint k=base+t;WorkAWrite(int2(line,k),gid.z,FFTShared[t]);}
}
#define Scene_Y_OUT WorkARead
#if V2_FY >= 2048
[numthreads(256,1,1)]void CS_SceneY2048(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=2048;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 4096
[numthreads(256,1,1)]void CS_SceneY4096(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=4096;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
#if V2_FY >= 8192
[numthreads(256,1,1)]void CS_SceneY8192(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=8192;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 16384
[numthreads(256,1,1)]void CS_SceneY16384(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=16384;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
#if V2_FY >= 32768
[numthreads(256,1,1)]void CS_SceneY32768(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=32768;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 65536
[numthreads(256,1,1)]void CS_SceneY65536(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=65536;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
#if V2_FY >= 131072
[numthreads(256,1,1)]void CS_SceneY131072(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=131072;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 262144
[numthreads(256,1,1)]void CS_SceneY262144(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=262144;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
#if V2_FY >= 524288
[numthreads(256,1,1)]void CS_SceneY524288(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=524288;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 1048576
[numthreads(256,1,1)]void CS_SceneY1048576(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=1048576;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
#if V2_FY >= 2097152
[numthreads(256,1,1)]void CS_SceneY2097152(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=2097152;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 4194304
[numthreads(256,1,1)]void CS_SceneY4194304(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=4194304;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
#if V2_FY >= 8388608
[numthreads(256,1,1)]void CS_SceneY8388608(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=8388608;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 16777216
[numthreads(256,1,1)]void CS_SceneY16777216(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=16777216;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
#if V2_FY >= 33554432
[numthreads(256,1,1)]void CS_SceneY33554432(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=33554432;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 67108864
[numthreads(256,1,1)]void CS_SceneY67108864(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=67108864;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
#if V2_FY >= 134217728
[numthreads(256,1,1)]void CS_SceneY134217728(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=134217728;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 268435456
[numthreads(256,1,1)]void CS_SceneY268435456(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=268435456;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
#if V2_FY >= 536870912
[numthreads(256,1,1)]void CS_SceneY536870912(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=536870912;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkBRead
#endif
#if V2_FY >= 1073741824
[numthreads(256,1,1)]void CS_SceneY1073741824(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=1073741824;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=-1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Scene_Y_OUT
#define Scene_Y_OUT WorkARead
#endif
[numthreads(16,16,1)]void CS_Multiply(uint3 id:SV_DispatchThreadID){
 if(Empty()||id.x>=V2_FX||id.y>=V2_FY)return;
 RowTempWrite(int2(id.xy),id.z,Cmul(Scene_Y_OUT(int2(id.xy),id.z),TransferRead(int2(id.xy),id.z)));
}
[numthreads(256,1,1)]void CS_InverseXLocal(uint3 gid:SV_GroupID,uint3 tid:SV_GroupThreadID){
 if(!(!Empty()))return;
 const uint N=V2_FX,B=min(N,1024u);uint line=gid.y,base=gid.x*B;
 for(uint t=tid.x;t<B;t+=256){uint j=BitReverse(base+t,N);FFTShared[t]=RowTempRead(int2(j,line),gid.z);}
 barrier();
 for(uint span=2;span<=B;span<<=1){
  for(uint b=tid.x;b<B/2;b+=256){uint k=b%(span/2),i=(b/(span/2))*span+k;
   float angle=1*2*PI*float(k)/float(span);float2 x=FFTShared[i],y=Cmul(FFTShared[i+span/2],float2(cos(angle),sin(angle)));
   FFTShared[i]=x+y;FFTShared[i+span/2]=x-y;
  }barrier();
 }
 for(uint t=tid.x;t<B;t+=256){uint k=base+t;WorkAWrite(int2(k,line),gid.z,FFTShared[t]);}
}
#define Inverse_X_OUT WorkARead
#if V2_FX >= 2048
[numthreads(256,1,1)]void CS_InverseX2048(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=2048;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 4096
[numthreads(256,1,1)]void CS_InverseX4096(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=4096;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
#if V2_FX >= 8192
[numthreads(256,1,1)]void CS_InverseX8192(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=8192;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 16384
[numthreads(256,1,1)]void CS_InverseX16384(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=16384;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
#if V2_FX >= 32768
[numthreads(256,1,1)]void CS_InverseX32768(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=32768;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 65536
[numthreads(256,1,1)]void CS_InverseX65536(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=65536;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
#if V2_FX >= 131072
[numthreads(256,1,1)]void CS_InverseX131072(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=131072;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 262144
[numthreads(256,1,1)]void CS_InverseX262144(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=262144;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
#if V2_FX >= 524288
[numthreads(256,1,1)]void CS_InverseX524288(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=524288;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 1048576
[numthreads(256,1,1)]void CS_InverseX1048576(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=1048576;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
#if V2_FX >= 2097152
[numthreads(256,1,1)]void CS_InverseX2097152(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=2097152;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 4194304
[numthreads(256,1,1)]void CS_InverseX4194304(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=4194304;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
#if V2_FX >= 8388608
[numthreads(256,1,1)]void CS_InverseX8388608(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=8388608;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 16777216
[numthreads(256,1,1)]void CS_InverseX16777216(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=16777216;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
#if V2_FX >= 33554432
[numthreads(256,1,1)]void CS_InverseX33554432(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=33554432;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 67108864
[numthreads(256,1,1)]void CS_InverseX67108864(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=67108864;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
#if V2_FX >= 134217728
[numthreads(256,1,1)]void CS_InverseX134217728(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=134217728;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 268435456
[numthreads(256,1,1)]void CS_InverseX268435456(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=268435456;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
#if V2_FX >= 536870912
[numthreads(256,1,1)]void CS_InverseX536870912(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=536870912;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(i,line),id.z),y=Cmul(WorkARead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(i,line),id.z,x+y);WorkBWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkBRead
#endif
#if V2_FX >= 1073741824
[numthreads(256,1,1)]void CS_InverseX1073741824(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX/2||id.y>=V2_FY)return;
 const uint span=1073741824;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(i,line),id.z),y=Cmul(WorkBRead(int2(i+span/2,line),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(i,line),id.z,x+y);WorkAWrite(int2(i+span/2,line),id.z,x-y);
}
#undef Inverse_X_OUT
#define Inverse_X_OUT WorkARead
#endif
[numthreads(16,16,1)]void CS_InverseRowsCommit(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FX||id.y>=V2_FY)return;
 RowTempWrite(int2(id.xy),id.z,Inverse_X_OUT(int2(id.xy),id.z));
}
[numthreads(256,1,1)]void CS_InverseYLocal(uint3 gid:SV_GroupID,uint3 tid:SV_GroupThreadID){
 if(!(!Empty()))return;
 const uint N=V2_FY,B=min(N,1024u);uint line=gid.y,base=gid.x*B;
 for(uint t=tid.x;t<B;t+=256){uint j=BitReverse(base+t,N);FFTShared[t]=RowTempRead(int2(line,j),gid.z);}
 barrier();
 for(uint span=2;span<=B;span<<=1){
  for(uint b=tid.x;b<B/2;b+=256){uint k=b%(span/2),i=(b/(span/2))*span+k;
   float angle=1*2*PI*float(k)/float(span);float2 x=FFTShared[i],y=Cmul(FFTShared[i+span/2],float2(cos(angle),sin(angle)));
   FFTShared[i]=x+y;FFTShared[i+span/2]=x-y;
  }barrier();
 }
 for(uint t=tid.x;t<B;t+=256){uint k=base+t;WorkAWrite(int2(line,k),gid.z,FFTShared[t]);}
}
#define Inverse_Y_OUT WorkARead
#if V2_FY >= 2048
[numthreads(256,1,1)]void CS_InverseY2048(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=2048;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 4096
[numthreads(256,1,1)]void CS_InverseY4096(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=4096;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
#if V2_FY >= 8192
[numthreads(256,1,1)]void CS_InverseY8192(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=8192;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 16384
[numthreads(256,1,1)]void CS_InverseY16384(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=16384;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
#if V2_FY >= 32768
[numthreads(256,1,1)]void CS_InverseY32768(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=32768;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 65536
[numthreads(256,1,1)]void CS_InverseY65536(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=65536;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
#if V2_FY >= 131072
[numthreads(256,1,1)]void CS_InverseY131072(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=131072;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 262144
[numthreads(256,1,1)]void CS_InverseY262144(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=262144;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
#if V2_FY >= 524288
[numthreads(256,1,1)]void CS_InverseY524288(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=524288;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 1048576
[numthreads(256,1,1)]void CS_InverseY1048576(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=1048576;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
#if V2_FY >= 2097152
[numthreads(256,1,1)]void CS_InverseY2097152(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=2097152;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 4194304
[numthreads(256,1,1)]void CS_InverseY4194304(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=4194304;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
#if V2_FY >= 8388608
[numthreads(256,1,1)]void CS_InverseY8388608(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=8388608;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 16777216
[numthreads(256,1,1)]void CS_InverseY16777216(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=16777216;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
#if V2_FY >= 33554432
[numthreads(256,1,1)]void CS_InverseY33554432(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=33554432;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 67108864
[numthreads(256,1,1)]void CS_InverseY67108864(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=67108864;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
#if V2_FY >= 134217728
[numthreads(256,1,1)]void CS_InverseY134217728(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=134217728;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 268435456
[numthreads(256,1,1)]void CS_InverseY268435456(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=268435456;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
#if V2_FY >= 536870912
[numthreads(256,1,1)]void CS_InverseY536870912(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=536870912;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkARead(int2(line,i),id.z),y=Cmul(WorkARead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkBWrite(int2(line,i),id.z,x+y);WorkBWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkBRead
#endif
#if V2_FY >= 1073741824
[numthreads(256,1,1)]void CS_InverseY1073741824(uint3 id:SV_DispatchThreadID){
 if(!(!Empty())||id.x>=V2_FY/2||id.y>=V2_FX)return;
 const uint span=1073741824;uint k=id.x%(span/2),i=(id.x/(span/2))*span+k,line=id.y;
 float angle=1*2*PI*float(k)/float(span);
 float2 x=WorkBRead(int2(line,i),id.z),y=Cmul(WorkBRead(int2(line,i+span/2),id.z),float2(cos(angle),sin(angle)));
 WorkAWrite(int2(line,i),id.z,x+y);WorkAWrite(int2(line,i+span/2),id.z,x-y);
}
#undef Inverse_Y_OUT
#define Inverse_Y_OUT WorkARead
#endif
[numthreads(8,8,1)]void CS_Bloom(uint3 id:SV_DispatchThreadID){
 if(id.x>=V2_W||id.y>=V2_H)return;int2 p=int2(id.xy)+V2_BORDER;float3 v=0;
 if(!Empty())v=max(float3(Inverse_Y_OUT(p,0).x,Inverse_Y_OUT(p,1).x,Inverse_Y_OUT(p,2).x),0);
 tex2Dstore(BloomU,int2(id.xy),float4(v,1));
}
[numthreads(8,8,1)]void CS_SourceHistory(uint3 id:SV_DispatchThreadID){
 if(id.x<V2_W&&id.y<V2_H)tex2Dstore(SourceHistoryU,int2(id.xy),tex2Dfetch(SourceS,int2(id.xy)));
}
void VS_Fullscreen(uint id:SV_VertexID,out float4 pos:SV_Position,out float2 uv:TEXCOORD0){
 uv=float2((id<<1)&2,id&2);pos=float4(uv*float2(2,-2)+float2(-1,1),0,1);
}
float3 OpticsPreview(float2 pixel){
 float2 screen=float2(BUFFER_WIDTH,BUFFER_HEIGHT);
 float fit=min(screen.y*0.9,screen.x*0.46);
 float side=PreviewNative?V2_K*max(PreviewZoom,0.0001):fit*max(PreviewZoom,0.0001);
 float2 center=float2(screen.x*(pixel.x<screen.x*0.5?0.25:0.75),screen.y*0.5);
 // Pupil and kernel are both SQUARE; no screen-aspect UV correction is used.
 float2 uv=(pixel-center)/side+0.5;
 float3 value=float3(0.008,0.008,0.01);
 if(all(uv>=0)&&all(uv<=1)){
  if(pixel.x<screen.x*0.5)value=tex2Dlod(ApertureS,float4(uv,0,0)).r.xxx;
  else{
   value=tex2Dlod(RawKernelS,float4(uv,0,0)).rgb*exp2(PreviewExposure);
   if(PreviewLog)value=log2(1+max(value,0)*32)/log2(33.0);
  }
 }
 return value;
}
float4 PS_Composite(float4 pos:SV_Position,float2 uv:TEXCOORD0):SV_Target{
 float3 scene=Decode(tex2Dlod(GameS,float4(uv,0,0)).rgb);
 // Uniform display-pixel spacing even when the display dimensions are not
 // divisible by DIV: scene texel i is centred at (i+0.5)*DIV pixels.
 float2 workUV=uv*float2(BUFFER_WIDTH,BUFFER_HEIGHT)/(float2(V2_W,V2_H)*V2_DIV);
 float3 source=tex2Dlod(SourceS,float4(workUV,0,0)).rgb;
 float3 bloom=Saturation(tex2Dlod(BloomS,float4(workUV,0,0)).rgb,BloomSaturation)*BloomTint*BloomIntensity;
 float3 result=scene;
 if(DebugView==1)result=source;
 else if(DebugView==2)result=bloom;
 else if(DebugView==3)result=OpticsPreview(pos.xy);
 else if(BlendMode==1)result=scene+(1-saturate(scene))*saturate(bloom);
 else if(BlendMode==2)result=max(scene-source*min(BloomIntensity,1),0)+bloom;
 else result=scene+bloom;
 if(OutputClamp&&InputSpace==0)result=saturate(result);
 return float4(Encode(result),1);
}

technique OpticalFFTBloomV2 < ui_label="Optical FFT Bloom v2.3"; ui_tooltip="Standalone procedural optics. Resolution: OFB2_APERTURE_SIZE and OFB2_RENDER_DIVISOR in effect preprocessor definitions; no shader-imposed resolution ceiling."; > {
 pass CacheState { ComputeShader=CS_CacheState; DispatchSizeX=1; DispatchSizeY=1; DispatchSizeZ=1; GenerateMipMaps=false; }
 pass Aperture { ComputeShader=CS_Aperture; DispatchSizeX=(V2_N+7)/8; DispatchSizeY=(V2_N+7)/8; DispatchSizeZ=1; GenerateMipMaps=false; }
 pass PupilXLocal { ComputeShader=CS_PupilXLocal; DispatchSizeX=(V2_N+1023)/1024; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#if V2_N >= 2048
 pass PupilX2048 { ComputeShader=CS_PupilX2048; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 4096
 pass PupilX4096 { ComputeShader=CS_PupilX4096; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 8192
 pass PupilX8192 { ComputeShader=CS_PupilX8192; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 16384
 pass PupilX16384 { ComputeShader=CS_PupilX16384; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 32768
 pass PupilX32768 { ComputeShader=CS_PupilX32768; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 65536
 pass PupilX65536 { ComputeShader=CS_PupilX65536; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 131072
 pass PupilX131072 { ComputeShader=CS_PupilX131072; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 262144
 pass PupilX262144 { ComputeShader=CS_PupilX262144; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 524288
 pass PupilX524288 { ComputeShader=CS_PupilX524288; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 1048576
 pass PupilX1048576 { ComputeShader=CS_PupilX1048576; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 2097152
 pass PupilX2097152 { ComputeShader=CS_PupilX2097152; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 4194304
 pass PupilX4194304 { ComputeShader=CS_PupilX4194304; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 8388608
 pass PupilX8388608 { ComputeShader=CS_PupilX8388608; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 16777216
 pass PupilX16777216 { ComputeShader=CS_PupilX16777216; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 33554432
 pass PupilX33554432 { ComputeShader=CS_PupilX33554432; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 67108864
 pass PupilX67108864 { ComputeShader=CS_PupilX67108864; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 134217728
 pass PupilX134217728 { ComputeShader=CS_PupilX134217728; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 268435456
 pass PupilX268435456 { ComputeShader=CS_PupilX268435456; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 536870912
 pass PupilX536870912 { ComputeShader=CS_PupilX536870912; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 1073741824
 pass PupilX1073741824 { ComputeShader=CS_PupilX1073741824; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
 pass PupilRowsCommit { ComputeShader=CS_PupilRowsCommit; DispatchSizeX=(V2_N+15)/16; DispatchSizeY=(V2_N+15)/16; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
 pass PupilYLocal { ComputeShader=CS_PupilYLocal; DispatchSizeX=(V2_N+1023)/1024; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#if V2_N >= 2048
 pass PupilY2048 { ComputeShader=CS_PupilY2048; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 4096
 pass PupilY4096 { ComputeShader=CS_PupilY4096; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 8192
 pass PupilY8192 { ComputeShader=CS_PupilY8192; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 16384
 pass PupilY16384 { ComputeShader=CS_PupilY16384; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 32768
 pass PupilY32768 { ComputeShader=CS_PupilY32768; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 65536
 pass PupilY65536 { ComputeShader=CS_PupilY65536; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 131072
 pass PupilY131072 { ComputeShader=CS_PupilY131072; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 262144
 pass PupilY262144 { ComputeShader=CS_PupilY262144; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 524288
 pass PupilY524288 { ComputeShader=CS_PupilY524288; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 1048576
 pass PupilY1048576 { ComputeShader=CS_PupilY1048576; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 2097152
 pass PupilY2097152 { ComputeShader=CS_PupilY2097152; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 4194304
 pass PupilY4194304 { ComputeShader=CS_PupilY4194304; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 8388608
 pass PupilY8388608 { ComputeShader=CS_PupilY8388608; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 16777216
 pass PupilY16777216 { ComputeShader=CS_PupilY16777216; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 33554432
 pass PupilY33554432 { ComputeShader=CS_PupilY33554432; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 67108864
 pass PupilY67108864 { ComputeShader=CS_PupilY67108864; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 134217728
 pass PupilY134217728 { ComputeShader=CS_PupilY134217728; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 268435456
 pass PupilY268435456 { ComputeShader=CS_PupilY268435456; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 536870912
 pass PupilY536870912 { ComputeShader=CS_PupilY536870912; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
#if V2_N >= 1073741824
 pass PupilY1073741824 { ComputeShader=CS_PupilY1073741824; DispatchSizeX=(V2_N/2+255)/256; DispatchSizeY=V2_N; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
#endif
 pass OpticalIntensity { ComputeShader=CS_OpticalIntensity; DispatchSizeX=(V2_N+7)/8; DispatchSizeY=(V2_N+7)/8; DispatchSizeZ=V2_WAVES; GenerateMipMaps=false; }
 pass RawKernel { ComputeShader=CS_RawKernel; DispatchSizeX=(V2_K+7)/8; DispatchSizeY=(V2_K+7)/8; DispatchSizeZ=1; GenerateMipMaps=false; }
 pass KernelStatistics { ComputeShader=CS_KernelStatistics; DispatchSizeX=1; DispatchSizeY=1; DispatchSizeZ=1; GenerateMipMaps=false; }
 pass Extract { ComputeShader=CS_Extract; DispatchSizeX=(V2_W+15)/16; DispatchSizeY=(V2_H+15)/16; DispatchSizeZ=1; GenerateMipMaps=false; }
 pass SourceStatistics { ComputeShader=CS_SourceStatistics; DispatchSizeX=1; DispatchSizeY=1; DispatchSizeZ=1; GenerateMipMaps=false; }
 pass KernelXLocal { ComputeShader=CS_KernelXLocal; DispatchSizeX=(V2_FX+1023)/1024; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#if V2_FX >= 2048
 pass KernelX2048 { ComputeShader=CS_KernelX2048; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 4096
 pass KernelX4096 { ComputeShader=CS_KernelX4096; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 8192
 pass KernelX8192 { ComputeShader=CS_KernelX8192; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 16384
 pass KernelX16384 { ComputeShader=CS_KernelX16384; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 32768
 pass KernelX32768 { ComputeShader=CS_KernelX32768; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 65536
 pass KernelX65536 { ComputeShader=CS_KernelX65536; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 131072
 pass KernelX131072 { ComputeShader=CS_KernelX131072; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 262144
 pass KernelX262144 { ComputeShader=CS_KernelX262144; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 524288
 pass KernelX524288 { ComputeShader=CS_KernelX524288; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 1048576
 pass KernelX1048576 { ComputeShader=CS_KernelX1048576; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 2097152
 pass KernelX2097152 { ComputeShader=CS_KernelX2097152; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 4194304
 pass KernelX4194304 { ComputeShader=CS_KernelX4194304; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 8388608
 pass KernelX8388608 { ComputeShader=CS_KernelX8388608; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 16777216
 pass KernelX16777216 { ComputeShader=CS_KernelX16777216; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 33554432
 pass KernelX33554432 { ComputeShader=CS_KernelX33554432; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 67108864
 pass KernelX67108864 { ComputeShader=CS_KernelX67108864; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 134217728
 pass KernelX134217728 { ComputeShader=CS_KernelX134217728; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 268435456
 pass KernelX268435456 { ComputeShader=CS_KernelX268435456; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 536870912
 pass KernelX536870912 { ComputeShader=CS_KernelX536870912; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 1073741824
 pass KernelX1073741824 { ComputeShader=CS_KernelX1073741824; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
 pass KernelRowsCommit { ComputeShader=CS_KernelRowsCommit; DispatchSizeX=(V2_FX+15)/16; DispatchSizeY=(V2_FY+15)/16; DispatchSizeZ=3; GenerateMipMaps=false; }
 pass KernelYLocal { ComputeShader=CS_KernelYLocal; DispatchSizeX=(V2_FY+1023)/1024; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#if V2_FY >= 2048
 pass KernelY2048 { ComputeShader=CS_KernelY2048; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 4096
 pass KernelY4096 { ComputeShader=CS_KernelY4096; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 8192
 pass KernelY8192 { ComputeShader=CS_KernelY8192; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 16384
 pass KernelY16384 { ComputeShader=CS_KernelY16384; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 32768
 pass KernelY32768 { ComputeShader=CS_KernelY32768; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 65536
 pass KernelY65536 { ComputeShader=CS_KernelY65536; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 131072
 pass KernelY131072 { ComputeShader=CS_KernelY131072; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 262144
 pass KernelY262144 { ComputeShader=CS_KernelY262144; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 524288
 pass KernelY524288 { ComputeShader=CS_KernelY524288; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 1048576
 pass KernelY1048576 { ComputeShader=CS_KernelY1048576; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 2097152
 pass KernelY2097152 { ComputeShader=CS_KernelY2097152; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 4194304
 pass KernelY4194304 { ComputeShader=CS_KernelY4194304; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 8388608
 pass KernelY8388608 { ComputeShader=CS_KernelY8388608; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 16777216
 pass KernelY16777216 { ComputeShader=CS_KernelY16777216; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 33554432
 pass KernelY33554432 { ComputeShader=CS_KernelY33554432; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 67108864
 pass KernelY67108864 { ComputeShader=CS_KernelY67108864; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 134217728
 pass KernelY134217728 { ComputeShader=CS_KernelY134217728; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 268435456
 pass KernelY268435456 { ComputeShader=CS_KernelY268435456; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 536870912
 pass KernelY536870912 { ComputeShader=CS_KernelY536870912; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 1073741824
 pass KernelY1073741824 { ComputeShader=CS_KernelY1073741824; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
 pass KernelCommit { ComputeShader=CS_KernelCommit; DispatchSizeX=(V2_FX+15)/16; DispatchSizeY=(V2_FY+15)/16; DispatchSizeZ=3; GenerateMipMaps=false; }
 pass SceneXLocal { ComputeShader=CS_SceneXLocal; DispatchSizeX=(V2_FX+1023)/1024; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#if V2_FX >= 2048
 pass SceneX2048 { ComputeShader=CS_SceneX2048; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 4096
 pass SceneX4096 { ComputeShader=CS_SceneX4096; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 8192
 pass SceneX8192 { ComputeShader=CS_SceneX8192; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 16384
 pass SceneX16384 { ComputeShader=CS_SceneX16384; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 32768
 pass SceneX32768 { ComputeShader=CS_SceneX32768; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 65536
 pass SceneX65536 { ComputeShader=CS_SceneX65536; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 131072
 pass SceneX131072 { ComputeShader=CS_SceneX131072; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 262144
 pass SceneX262144 { ComputeShader=CS_SceneX262144; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 524288
 pass SceneX524288 { ComputeShader=CS_SceneX524288; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 1048576
 pass SceneX1048576 { ComputeShader=CS_SceneX1048576; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 2097152
 pass SceneX2097152 { ComputeShader=CS_SceneX2097152; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 4194304
 pass SceneX4194304 { ComputeShader=CS_SceneX4194304; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 8388608
 pass SceneX8388608 { ComputeShader=CS_SceneX8388608; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 16777216
 pass SceneX16777216 { ComputeShader=CS_SceneX16777216; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 33554432
 pass SceneX33554432 { ComputeShader=CS_SceneX33554432; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 67108864
 pass SceneX67108864 { ComputeShader=CS_SceneX67108864; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 134217728
 pass SceneX134217728 { ComputeShader=CS_SceneX134217728; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 268435456
 pass SceneX268435456 { ComputeShader=CS_SceneX268435456; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 536870912
 pass SceneX536870912 { ComputeShader=CS_SceneX536870912; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 1073741824
 pass SceneX1073741824 { ComputeShader=CS_SceneX1073741824; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
 pass SceneRowsCommit { ComputeShader=CS_SceneRowsCommit; DispatchSizeX=(V2_FX+15)/16; DispatchSizeY=(V2_FY+15)/16; DispatchSizeZ=3; GenerateMipMaps=false; }
 pass SceneYLocal { ComputeShader=CS_SceneYLocal; DispatchSizeX=(V2_FY+1023)/1024; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#if V2_FY >= 2048
 pass SceneY2048 { ComputeShader=CS_SceneY2048; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 4096
 pass SceneY4096 { ComputeShader=CS_SceneY4096; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 8192
 pass SceneY8192 { ComputeShader=CS_SceneY8192; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 16384
 pass SceneY16384 { ComputeShader=CS_SceneY16384; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 32768
 pass SceneY32768 { ComputeShader=CS_SceneY32768; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 65536
 pass SceneY65536 { ComputeShader=CS_SceneY65536; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 131072
 pass SceneY131072 { ComputeShader=CS_SceneY131072; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 262144
 pass SceneY262144 { ComputeShader=CS_SceneY262144; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 524288
 pass SceneY524288 { ComputeShader=CS_SceneY524288; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 1048576
 pass SceneY1048576 { ComputeShader=CS_SceneY1048576; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 2097152
 pass SceneY2097152 { ComputeShader=CS_SceneY2097152; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 4194304
 pass SceneY4194304 { ComputeShader=CS_SceneY4194304; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 8388608
 pass SceneY8388608 { ComputeShader=CS_SceneY8388608; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 16777216
 pass SceneY16777216 { ComputeShader=CS_SceneY16777216; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 33554432
 pass SceneY33554432 { ComputeShader=CS_SceneY33554432; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 67108864
 pass SceneY67108864 { ComputeShader=CS_SceneY67108864; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 134217728
 pass SceneY134217728 { ComputeShader=CS_SceneY134217728; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 268435456
 pass SceneY268435456 { ComputeShader=CS_SceneY268435456; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 536870912
 pass SceneY536870912 { ComputeShader=CS_SceneY536870912; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 1073741824
 pass SceneY1073741824 { ComputeShader=CS_SceneY1073741824; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
 pass Multiply { ComputeShader=CS_Multiply; DispatchSizeX=(V2_FX+15)/16; DispatchSizeY=(V2_FY+15)/16; DispatchSizeZ=3; GenerateMipMaps=false; }
 pass InverseXLocal { ComputeShader=CS_InverseXLocal; DispatchSizeX=(V2_FX+1023)/1024; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#if V2_FX >= 2048
 pass InverseX2048 { ComputeShader=CS_InverseX2048; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 4096
 pass InverseX4096 { ComputeShader=CS_InverseX4096; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 8192
 pass InverseX8192 { ComputeShader=CS_InverseX8192; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 16384
 pass InverseX16384 { ComputeShader=CS_InverseX16384; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 32768
 pass InverseX32768 { ComputeShader=CS_InverseX32768; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 65536
 pass InverseX65536 { ComputeShader=CS_InverseX65536; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 131072
 pass InverseX131072 { ComputeShader=CS_InverseX131072; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 262144
 pass InverseX262144 { ComputeShader=CS_InverseX262144; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 524288
 pass InverseX524288 { ComputeShader=CS_InverseX524288; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 1048576
 pass InverseX1048576 { ComputeShader=CS_InverseX1048576; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 2097152
 pass InverseX2097152 { ComputeShader=CS_InverseX2097152; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 4194304
 pass InverseX4194304 { ComputeShader=CS_InverseX4194304; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 8388608
 pass InverseX8388608 { ComputeShader=CS_InverseX8388608; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 16777216
 pass InverseX16777216 { ComputeShader=CS_InverseX16777216; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 33554432
 pass InverseX33554432 { ComputeShader=CS_InverseX33554432; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 67108864
 pass InverseX67108864 { ComputeShader=CS_InverseX67108864; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 134217728
 pass InverseX134217728 { ComputeShader=CS_InverseX134217728; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 268435456
 pass InverseX268435456 { ComputeShader=CS_InverseX268435456; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 536870912
 pass InverseX536870912 { ComputeShader=CS_InverseX536870912; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FX >= 1073741824
 pass InverseX1073741824 { ComputeShader=CS_InverseX1073741824; DispatchSizeX=(V2_FX/2+255)/256; DispatchSizeY=V2_FY; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
 pass InverseRowsCommit { ComputeShader=CS_InverseRowsCommit; DispatchSizeX=(V2_FX+15)/16; DispatchSizeY=(V2_FY+15)/16; DispatchSizeZ=3; GenerateMipMaps=false; }
 pass InverseYLocal { ComputeShader=CS_InverseYLocal; DispatchSizeX=(V2_FY+1023)/1024; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#if V2_FY >= 2048
 pass InverseY2048 { ComputeShader=CS_InverseY2048; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 4096
 pass InverseY4096 { ComputeShader=CS_InverseY4096; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 8192
 pass InverseY8192 { ComputeShader=CS_InverseY8192; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 16384
 pass InverseY16384 { ComputeShader=CS_InverseY16384; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 32768
 pass InverseY32768 { ComputeShader=CS_InverseY32768; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 65536
 pass InverseY65536 { ComputeShader=CS_InverseY65536; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 131072
 pass InverseY131072 { ComputeShader=CS_InverseY131072; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 262144
 pass InverseY262144 { ComputeShader=CS_InverseY262144; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 524288
 pass InverseY524288 { ComputeShader=CS_InverseY524288; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 1048576
 pass InverseY1048576 { ComputeShader=CS_InverseY1048576; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 2097152
 pass InverseY2097152 { ComputeShader=CS_InverseY2097152; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 4194304
 pass InverseY4194304 { ComputeShader=CS_InverseY4194304; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 8388608
 pass InverseY8388608 { ComputeShader=CS_InverseY8388608; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 16777216
 pass InverseY16777216 { ComputeShader=CS_InverseY16777216; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 33554432
 pass InverseY33554432 { ComputeShader=CS_InverseY33554432; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 67108864
 pass InverseY67108864 { ComputeShader=CS_InverseY67108864; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 134217728
 pass InverseY134217728 { ComputeShader=CS_InverseY134217728; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 268435456
 pass InverseY268435456 { ComputeShader=CS_InverseY268435456; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 536870912
 pass InverseY536870912 { ComputeShader=CS_InverseY536870912; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
#if V2_FY >= 1073741824
 pass InverseY1073741824 { ComputeShader=CS_InverseY1073741824; DispatchSizeX=(V2_FY/2+255)/256; DispatchSizeY=V2_FX; DispatchSizeZ=3; GenerateMipMaps=false; }
#endif
 pass Bloom { ComputeShader=CS_Bloom; DispatchSizeX=(V2_W+7)/8; DispatchSizeY=(V2_H+7)/8; DispatchSizeZ=1; GenerateMipMaps=false; }
 pass SourceHistory { ComputeShader=CS_SourceHistory; DispatchSizeX=(V2_W+7)/8; DispatchSizeY=(V2_H+7)/8; DispatchSizeZ=1; GenerateMipMaps=false; }
 pass CacheCommit { ComputeShader=CS_CacheCommit; DispatchSizeX=1; DispatchSizeY=1; DispatchSizeZ=1; GenerateMipMaps=false; }
 pass Composite { VertexShader=VS_Fullscreen; PixelShader=PS_Composite; }
}
