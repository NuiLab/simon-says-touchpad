/*************************************************************************
* Constants/Globals
*************************************************************************/

#define ONE_OVER_PI 0.318310
#define PI_OVER_TWO 1.570796
#define PI 3.14159
#define TAU 6.283185

#define EPSILON 0.00001

#define V_FOWARD vec3(1., 0., 0.)
#define V_UP vec3(0., 1., 0.)

#define DISTMARCH_STEPS 60
#define DISTMARCH_MAXDIST 50.

#define MAT_WHITE 1.
#define MAT_GRAY 2.
#define MAT_RED 3.
#define MAT_LIGHTRED 4.
#define MAT_ORANGE 5.
#define MAT_LIGHTORANGE 6.
#define MAT_GREEN 7.
#define MAT_LIGHTGREEN 8.
#define MAT_BLUE 9.
#define MAT_LIGHTBLUE 10.

#define SKYGRAY vec3(.99)
#define SKYWHITE vec3(0.9)

uniform vec4 other;

//Globals
vec3 g_camPointAt = vec3(1., 0., 0.);
vec3 g_camOrigin = vec3(0., 5., 0.);
vec3 g_ldir = vec3(-.4, 1., -.3);

//Camera Data
struct CameraData
{
  vec3 origin;
  vec3 dir;
  vec2 st;
};

struct SurfaceData
{
  vec3 point;
  vec3 normal;
  vec3 basecolor;
  float roughness;
  float metallic;
};

/*************************************************************************
* Utilities
*************************************************************************/

vec2 opU(vec2 a, vec2 b)
{
  if (a.x < b.x)
    return a;
  else
    return b;
}

float opS(float d1, float d2)
{
  return max(-d2, d1);
}

vec3 opCheapBend(vec3 p, vec2 a)
{
  float c = cos(a.x * p.y);
  float s = sin(a.y * p.y);
  mat2 m = mat2(c, -s, s, c);
  return vec3(m * p.xy, p.z);
}

float pow5(float v)
{
  float tmp = v * v;
  return tmp * tmp * v;
}

vec3 opTwist(vec3 p, float a)
{
  float c = cos(a * p.y + a);
  float s = sin(a * p.y + a);
  mat2 m = mat2(c, -s, s, c);
  return vec3(m * p.xz, p.y);
}

mat3 makeRotateX(float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat3(1.0, c, -s,
              0.0, s, c,
              0.0, 0.0, 1.0);
}

mat3 makeRotateY(float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat3(c, 0.0, s,
              0.0, 1.0, 0.0,
              -s, 0.0, c);
}

mat3 makeRotateZ(float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat3(c, -s, 0.0,
              s, c, 0.0,
              0.0, 0.0, 1.0);
}

vec2 cartesianToPolar(vec2 p)
{
  float l = length(p);
  return vec2(acos(p.x / l), asin(p.y / l));
}

vec2 cartesianToPolar(vec3 p)
{
  return vec2(PI / 2. - acos(p.y / length(p)), atan(p.z, p.x));
}

vec3 DomainRotateSymmetry(const in vec3 vPos, const in float fSteps)
{
  float angle = atan(vPos.x, vPos.z);

  float fScale = fSteps / (PI * 2.0);
  float steppedAngle = (floor(angle * fScale + 0.5)) / fScale;

  float s = sin(-steppedAngle);
  float c = cos(-steppedAngle);

  vec3 vResult = vec3(c * vPos.x + s * vPos.z,
                      vPos.y,
                      -s * vPos.x + c * vPos.z);

  return vResult;
}

float lstep(float edge0, float edge1, float x)
{
  return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

/*************************************************************************
* Distance Functions
*************************************************************************/

float sdPlane(vec3 p)
{
  return p.y;
}

float sdPlaneZ(vec3 p)
{
  return p.z;
}

float sdRoundBox(vec3 p, vec3 b, float r)
{
  return length(max(abs(p) - b, 0.0)) - r;
}

float sdBox(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdRoundCylinder(vec3 p, vec2 h, float r)
{
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}

vec2 sdSimonSays(vec3 p, vec4 lights)
{
  vec2 base = vec2(sdRoundCylinder(p, vec2(2., .075), .1), MAT_GRAY);

  float col = MAT_RED;

  if (p.x > 0. && p.z > 0.)
  {
    col = MAT_ORANGE + lights.y;
  }
  else if (p.x > 0. && p.z < 0.)
  {
    col = MAT_RED + lights.x;
  }
  else if (p.x < 0. && p.z > 0.)
  {
    col = MAT_GREEN + lights.z;
  }
  else
  {
    col = MAT_BLUE + lights.w;
  }

  if (lights.x > 0.)
  {
    if (p.x > 0. && p.z < 0.)
    {
      p.y += .05;
    }
  }
  else if (lights.y > 0.)
  {
    if (p.x > 0. && p.z > 0.)
    {
      p.y += .05;
    }
  }
  else if (lights.z > 0.)
  {
    if (p.x < 0. && p.z > 0.)
    {
      p.y += .05;
    }
  }
  else if (lights.w > 0.)
  {
    if (p.x < 0. && p.z < 0.)
    {
      p.y += .05;
    }
  }

  float b = sdRoundCylinder(p, vec2(1.8, .25), 0.);
  b = opS(b, sdBox(p, vec3(3., 1., .1)));
  b = opS(b, sdBox(p, vec3(.1, 1., 3.))) - .05;
  vec2 buttons = vec2(b, col);

  return opU(base, buttons);
}

vec2 scenedf(vec3 p)
{
  vec2 obj = vec2(sdPlane((p + vec3(0., .2, 0.))), MAT_WHITE);
  obj = opU(obj, sdSimonSays(p + vec3(-5., 0., 0.), other));

  return obj;
}

/*************************************************************************
* Camera
*************************************************************************/

CameraData setupCamera(vec2 st)
{
  // calculate the ray origin and ray direction that represents
  // mapping the image plane towards the scene
  vec3 iu = vec3(0., 1., 0.);

  vec3 iz = normalize(g_camPointAt - g_camOrigin);
  vec3 ix = normalize(cross(iz, iu));
  vec3 iy = cross(ix, iz);
  float fov = .67;

  vec3 dir = normalize(st.x * ix + st.y * iy + fov * iz);

  return CameraData(g_camOrigin, dir, st);
}

void animateCamera()
{
  //Camera
  g_camOrigin = vec3(0., 3.68, 0.); //1.68

  vec2 click = (mouse.xy / resolution.xx) - vec2(.5, -0.5);
  click = vec2(0.7, 0.25) * click;

  float yaw = PI_OVER_TWO * (click.x);
  float pitch = PI_OVER_TWO * ((resolution.x / resolution.y) * -click.y);

  g_camPointAt = g_camOrigin + vec3(cos(yaw), tan(pitch) * cos(yaw), sin(yaw));
}

/*************************************************************************
* Rendering
*************************************************************************/

//Just like a camera has an origin and point it's looking at.
vec2 distmarch(vec3 rayOrigin, vec3 rayDestination, float maxd)
{
  //Camera Near
  //Step Size
  float dist = 10. * EPSILON;
  //Steps
  float t = 0.;
  //Materials behave like Color ID Maps, a range of values is a material.
  float material = 0.;

  //March
  for (int i = 0; i < DISTMARCH_STEPS; i++)
  {
    // Near/Far Planes
    if (abs(dist) < EPSILON || t > maxd)
      break;

    // advance the distance of the last lookup
    t += dist;
    vec2 dfresult = scenedf(rayOrigin + t * rayDestination);
    dist = dfresult.x;
    material = dfresult.y;
  }

  //Camera Far
  if (t > maxd)
    material = -1.0;

  //So we return the ray's collision and the material on that collision.
  return vec2(t, material);
}

// SHADOWING & NORMALS

#define SOFTSHADOW_STEPS 40
#define SOFTSHADOW_STEPSIZE .1

float calcSoftShadow(vec3 ro, vec3 rd, float mint, float maxt, float k)
{
  float shadow = 1.0;
  float t = mint;

  for (int i = 0; i < SOFTSHADOW_STEPS; i++)
  {
    if (t < maxt)
    {
      float h = scenedf(ro + rd * t).x;
      shadow = min(shadow, k * h / t);
      t += SOFTSHADOW_STEPSIZE;
    }
  }
  return clamp(shadow, 0.0, 1.0);
}

#define AO_NUMSAMPLES 6
#define AO_STEPSIZE .1
#define AO_STEPSCALE .4

float calcAO(vec3 p, vec3 n)
{
  float ao = 0.0;
  float aoscale = 1.0;

  for (int aoi = 0; aoi < AO_NUMSAMPLES; aoi++)
  {
    float stepp = 0.01 + AO_STEPSIZE * float(aoi);
    vec3 aop = n * stepp + p;

    float d = scenedf(aop).x;
    ao += -(d - stepp) * aoscale;
    aoscale *= AO_STEPSCALE;
  }

  return clamp(ao, 0.0, 1.0);
}

// SHADING

#define INITSURF(p, n) SurfaceData(p, n, vec3(0.), 0., 0.)

vec3 calcNormal(vec3 p)
{
  vec3 epsilon = vec3(0.001, 0.0, 0.0);
  vec3 n = vec3(
      scenedf(p + epsilon.xyy).x - scenedf(p - epsilon.xyy).x,
      scenedf(p + epsilon.yxy).x - scenedf(p - epsilon.yxy).x,
      scenedf(p + epsilon.yyx).x - scenedf(p - epsilon.yyx).x);
  return normalize(n);
}

void material(float surfid, inout SurfaceData surf)
{
  if (surfid - .5 < MAT_WHITE)
  {
    surf.basecolor = vec3(.91);
    surf.roughness = .99;
    surf.metallic = .01;
  }
  else if (surfid - .5 < MAT_GRAY)
  {
    surf.basecolor = vec3(0.2);
    surf.roughness = .95;
    surf.metallic = .3;
  }
  else if (surfid - .5 < MAT_RED)
  {
    surf.basecolor = vec3(.8, .1, .1);
    surf.roughness = .95;
    surf.metallic = .1;
  }
  else if (surfid - .5 < MAT_LIGHTRED)
  {
    surf.basecolor = vec3(2., .3, .3);
    surf.roughness = .95;
    surf.metallic = .14;
  }
  else if (surfid - .5 < MAT_ORANGE)
  {
    surf.basecolor = vec3(.9, .4, .1);
    surf.roughness = .95;
    surf.metallic = .1;
  }
  else if (surfid - .5 < MAT_LIGHTORANGE)
  {
    surf.basecolor = vec3(3., 1.5, .12);
    surf.roughness = .9;
    surf.metallic = .1;
  }
  else if (surfid - .5 < MAT_GREEN)
  {
    surf.basecolor = vec3(.2, .8, .3);
    surf.roughness = .95;
    surf.metallic = .1;
  }
  else if (surfid - .5 < MAT_LIGHTGREEN)
  {
    surf.basecolor = vec3(.3, 1.98, .3);
    surf.roughness = .95;
    surf.metallic = .1;
  }
  else if (surfid - .5 < MAT_BLUE)
  {
    surf.basecolor = vec3(.3, .4, .8);
    surf.roughness = .95;
    surf.metallic = .1;
  }
  else if (surfid - .5 < MAT_LIGHTBLUE)
  {
    surf.basecolor = vec3(.5, .5, 1.98);
    surf.roughness = .95;
    surf.metallic = .1;
  }
}

vec3 integrateDirLight(vec3 ldir, vec3 lcolor, SurfaceData surf)
{
  vec3 vdir = normalize(g_camOrigin - surf.point);
  vec3 hdir = normalize(ldir + vdir);

  float costh = max(-EPSILON, dot(surf.normal, hdir));
  float costd = max(-EPSILON, dot(ldir, hdir));
  float costl = max(-EPSILON, dot(surf.normal, ldir));
  float costv = max(-EPSILON, dot(surf.normal, vdir));

  float ndl = clamp(costl, 0., 1.);

  vec3 cout = vec3(0.);

  if (ndl > 0.)
  {
    float frk = .5 + 2. * costd * costd * surf.roughness;
    vec3 diff = surf.basecolor * ONE_OVER_PI * (1. + (frk - 1.) * pow5(1. - costl)) * (1. + (frk - 1.) * pow5(1. - costv));

    float r = max(0.05, surf.roughness);
    float alpha = r * r;
    float denom = costh * costh * (alpha * alpha - 1.) + 1.;
    float D = (alpha * alpha) / (PI * denom * denom);

    float k = ((r + 1.) * (r + 1.)) / 8.;
    float Gl = costv / (costv * (1. - k) + k);
    float Gv = costl / (costl * (1. - k) + k);
    float G = Gl * Gv;

    vec3 F0 = mix(vec3(.5), surf.basecolor, surf.metallic);
    vec3 F = F0 + (1. - F0) * pow5(1. - costd);

    vec3 spec = D * F * G / (4. * costl * costv);
    float shd = 1.0;
    calcSoftShadow(surf.point, ldir, 0.1, 20., 5.);

    cout += diff * ndl * shd * lcolor;
    cout += spec * ndl * shd * lcolor;
  }

  return cout;
}

vec3 sampleEnvLight(vec3 ldir, vec3 lcolor, SurfaceData surf)
{

  vec3 vdir = normalize(g_camOrigin - surf.point);
  vec3 hdir = normalize(ldir + vdir);
  float costh = dot(surf.normal, hdir);
  float costd = dot(ldir, hdir);
  float costl = dot(surf.normal, ldir);
  float costv = dot(surf.normal, vdir);

  float ndl = clamp(costl, 0., 1.);
  vec3 cout = vec3(0.);
  if (ndl > 0.)
  {
    float r = surf.roughness;
    float k = r * r / 2.;
    float Gl = costv / (costv * (1. - k) + k);
    float Gv = costl / (costl * (1. - k) + k);
    float G = Gl * Gv;

    vec3 F0 = mix(vec3(.5), surf.basecolor, surf.metallic);
    vec3 F = F0 + (1. - F0) * pow5(1. - costd);
    vec3 spec = lcolor * G * F * costd / (costh * costv);
    float shd = calcSoftShadow(surf.point, ldir, 0.02, 20., 7.);
    cout = spec * shd * lcolor;
  }

  return cout;
}

vec3 shadeSurface(SurfaceData surf)
{

  vec3 amb = surf.basecolor * .01;
  float ao = calcAO(surf.point, surf.normal);

  vec3 centerldir = normalize(-surf.point);

  vec3 cout = vec3(0.);
  if (dot(surf.basecolor, vec3(-1.)) > EPSILON)
  {
    cout = -surf.basecolor * surf.point.x; // + (0.2 * surf.normal);
  }
  else if (dot(surf.basecolor, vec3(1.)) > EPSILON)
  {
    vec3 dir1 = normalize(vec3(0.0, 0.9, 0.1));
    vec3 col1 = vec3(0.3, 0.5, .9);
    vec3 dir2 = normalize(vec3(0.1, -.1, 0.));
    vec3 col2 = vec3(0.94, 0.5, 0.2);
    cout += integrateDirLight(dir1, col1, surf);
    cout += integrateDirLight(dir2, .0 * col2, surf);
    cout += integrateDirLight(g_ldir, vec3(0.4), surf);
    //cout += integrateEnvLight(surf);
    cout *= (1. - (3.5 * ao));
  }
  return cout;
}

/*************************************************************************
* Postprocessing
*************************************************************************/

vec3 vignette(vec3 texel, vec2 vUv, float darkness, float offset)
{
  vec2 uv = (vUv - vec2(0.5)) * vec2(offset);
  return mix(texel.rgb, vec3(1.0 - darkness), dot(uv, uv));
}

vec3 overlay(vec3 inColor, vec3 overlay)
{
  vec3 outColor = vec3(0.);
  outColor.r = (inColor.r > 0.5) ? (1.0 - (1.0 - 2.0 * (inColor.r - 0.5)) * (1.0 - overlay.r)) : ((2.0 * inColor.r) * overlay.r);
  outColor.g = (inColor.g > 0.5) ? (1.0 - (1.0 - 2.0 * (inColor.g - 0.5)) * (1.0 - overlay.g)) : ((2.0 * inColor.g) * overlay.g);
  outColor.b = (inColor.b > 0.5) ? (1.0 - (1.0 - 2.0 * (inColor.b - 0.5)) * (1.0 - overlay.b)) : ((2.0 * inColor.b) * overlay.b);
  return outColor;
}

/*************************************************************************
* Main
*************************************************************************/

void main()
{

  // Setup
  vec2 aspectRatio = vec2(1., (resolution.y / resolution.x));
  vec2 uvv = ((uv - vec2(.5)) * aspectRatio) + vec2(.5);
  vec2 uvc = (uvv - vec2(.5));

  // Animate globals
  animateCamera();

  // Setup Camera
  CameraData cam = setupCamera(uvc);

  // Raymarch
  vec2 scenemarch = distmarch(cam.origin, cam.dir, DISTMARCH_MAXDIST);

  // Materials/Shading
  vec3 scenecol = vec3(0.);
  if (scenemarch.y > EPSILON)
  {
    vec3 mp = cam.origin + scenemarch.x * cam.dir;
    vec3 mn = calcNormal(mp);

    SurfaceData currSurf = INITSURF(mp, mn);

    material(scenemarch.y, currSurf);
    scenecol = shadeSurface(currSurf);
  }

  // Fog
  scenecol = mix(scenecol, SKYWHITE, smoothstep(0., 50., scenemarch.x));

  // Postprocessing
  scenecol = vignette(scenecol, uvv, 1.3, 0.9);

  gl_FragColor = vec4(scenecol, 1.0);
}