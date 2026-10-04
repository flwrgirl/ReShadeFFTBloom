# ReShadeFFTBloom
parameterised and procedural ai slop generated reshade shader for realistic convolution bloom

**ai disclaimer**: i did not write any of this code by hand other than the readme because im a stupid chud this is all computer generated but the shader is nice i gues. i cant read any of the code and i dont think any other human could either. i very much dislike ai but this is my one exception, you dont have to use this shader if you dont want to and i totally understand that. 

in an ideal world i wouldve learned graphics programming, any way here is some highlights:

- entirely procedural aperture texture drives the fft kernel
  - can do shit like add some imperfections and squeeze it and add struts like on space telescopes
- ability to choose the resolution of the frame that will be convolved
  - half res, third res, quarter res or any other integer
- ability to choose kernel resolution for fine details in the bloom
- various threshold controls so the whole image isnt convolved

### stuff that maybe will be added

as long as the free trial lasts ill tell the computer to add stuff like:
- custom aperture texture support
- cant think of anything else

preview images coming when i can be bothered

#### support human creation, free palestine
