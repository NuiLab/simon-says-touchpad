#version 450

/*************************************************************************
* Uniforms
*************************************************************************/

layout(set = 0, binding = 0) uniform Block {
    vec4 mouse;
    vec2 resolution;
    float time;
    float _padding1_;
    vec4 fabric;
} uniforms;

layout (location = 0) in vec2 iUV;
layout (location = 0) out vec4 oColor;

/*************************************************************************
* Constants/Globals
*************************************************************************/

#define ONE_OVER_PI 0.318310
#define PI_OVER_TWO 1.570796
#define PI 3.14159
#define TAU 6.283185

#define EPSILON 0.00001

#define V_FOWARD vec3(1.,0.,0.)
#define V_UP vec3(0.,1.,0.)

#define DISTMARCH_STEPS 60
#define DISTMARCH_MAXDIST 50.

//Globals
vec3  g_camPointAt = vec3(0.);
vec3  g_camOrigin = vec3(0.);
vec3  g_ldir = vec3(-.4, 1., -.3);

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
	if (a.x < b.x) return a;
	else return b;
}

float opS(float d1, float d2)
{
	return max(-d2, d1);
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

  vec3 dir = normalize(st.x*ix + st.y*iy + fov * iz);

  return CameraData(g_camOrigin, dir, st);

}

void animateCamera()
{
	//Camera
	g_camOrigin = vec3(0., 1.68, 0.); //1.68

	vec2 click = uniforms.mouse.xy / uniforms.resolution.xx;
	click = vec2(0.7, 0.25) * click + vec2(0., -0.05);

	float yaw = PI_OVER_TWO * (click.x);
	float pitch = PI_OVER_TWO * ((uniforms.resolution.x / uniforms.resolution.y) * click.y);

	g_camPointAt = g_camOrigin + vec3(cos(yaw), tan(pitch)*cos(yaw), sin(yaw));
}

/*************************************************************************
* Rendering
*************************************************************************/

//Just like a camera has an origin and point it's looking at.
vec2 distmarch( vec3 rayOrigin, vec3 rayDestination, float maxd )
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
    if ( abs(dist) < EPSILON || t > maxd ) break;

    // advance the distance of the last lookup
    t += dist;
    vec2 dfresult = scenedf( rayOrigin + t * rayDestination );
    dist = dfresult.x;
    material = dfresult.y;
  }

  //Camera Far
  if( t > maxd ) material = -1.0;

  //So we return the ray's collision and the material on that collision.
  return vec2( t, material );
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
		ao += -(d - stepp)*aoscale;
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
	if (surfid - .5 < MAT_GUNWHITE)
	{
		surf.basecolor = vec3(.94);
		surf.roughness = .85;
		surf.metallic = .4;
	}
	else if (surfid - .5 < MAT_GUNGRAY)
	{
		surf.basecolor = vec3(0.1);
		surf.roughness = 6.;
		surf.metallic = .3;
	}
	else if (surfid - .5 < MAT_GUNBLACK)
	{
		surf.basecolor = vec3(.05);
		surf.roughness = .6;
		surf.metallic = .4;
	}
	else if (surfid - .5 < MAT_FUNNEL)
	{
		surf.basecolor = -vec3(.1, .3, .9);
		surf.roughness = 1.;
		surf.metallic = 0.;
	}
	else if (surfid - .5 < MAT_CHAMBER)
	{
		surf.basecolor = vec3(6.5);
		surf.roughness = 0.89;
		surf.metallic = 0.2;
	}
}

vec3 integrateDirLight(vec3 ldir, vec3 lcolor, SurfaceData surf)
{
	vec3 vdir = normalize(g_camOrigin - surf.point);
	vec3 hdir = normalize(ldir + vdir);

	float costh = max(-SMALL_FLOAT, dot(surf.normal, hdir));
	float costd = max(-SMALL_FLOAT, dot(ldir, hdir));
	float costl = max(-SMALL_FLOAT, dot(surf.normal, ldir));
	float costv = max(-SMALL_FLOAT, dot(surf.normal, vdir));

	float ndl = clamp(costl, 0., 1.);

	vec3 cout = vec3(0.);

	if (ndl > 0.)
	{
		float frk = .5 + 2.* costd*costd * surf.roughness;
		vec3 diff = surf.basecolor * ONE_OVER_PI * (1. + (frk - 1.)*pow5(1. - costl)) * (1. + (frk - 1.) * pow5(1. - costv));

		float r = max(0.05, surf.roughness);
		float alpha = r * r;
		float denom = costh*costh * (alpha*alpha - 1.) + 1.;
		float D = (alpha*alpha) / (PI * denom*denom);

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
		//Rim Light
		//cout += clamp(pow(dot(vdir, -surf.normal) + 1.5, 3.5) * 0.05, 0.0, 1.0);
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
		float k = r*r / 2.;
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

vec3 integrateEnvLight(SurfaceData surf)
{
	vec3 vdir = normalize(surf.point - g_camOrigin);
	vec3 envdir = reflect(vdir, surf.normal);
	vec4 specolor = vec4(.4) * mix(texture(iChannel0, envdir), texture(iChannel1, envdir), surf.roughness);

	vec3 envspec = sampleEnvLight(envdir, specolor.rgb, surf);
	return envspec;
}

vec3 shadeSurface(SurfaceData surf)
{

	vec3 amb = surf.basecolor * .01;
	float ao = calcAO(surf.point, surf.normal);

	vec3 centerldir = normalize(-surf.point);

	vec3 cout = vec3(0.);
	if (dot(surf.basecolor, vec3(-1.)) > SMALL_FLOAT) //Excursion Funnel
	{
		cout = -surf.basecolor * surf.point.x;// + (0.2 * surf.normal);

	}
	else
		if (dot(surf.basecolor, vec3(1.)) > SMALL_FLOAT)
		{
			vec3  dir1 = normalize(vec3(0.0, 0.9, 0.1));
			vec3  col1 = vec3(0.3, 0.5, .9);
			vec3  dir2 = normalize(vec3(0.1, -.1, 0.));
			vec3  col2 = vec3(0.94, 0.5, 0.2);
			cout += integrateDirLight(dir1, col1, surf);
			cout += integrateDirLight(dir2, .0*col2, surf);
			cout += integrateDirLight(g_ldir, vec3(0.4), surf);
			cout += integrateEnvLight(surf);
			cout *= (1. - (3.5 * ao));
		}
	return cout;

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

float sdCylinder(vec3 p, vec2 h)
{
	vec2 d = abs(vec2(length(p.xz), p.y)) - h;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

vec2 scenedf(vec3 p)
{
    vec2 obj = vec2(sdPGunBlaster(gp), MAT_GUNGRAY);
    return obj;
}

/*************************************************************************
* Main
*************************************************************************/

void main()
{
    // Setup
    vec3 col = vec3(.157, .153, .169);
    vec2 aspectRatio = vec2(1., (uniforms.resolution.y / uniforms.resolution.x));
    vec2 uv = ((iUV - vec2(.5)) * aspectRatio) + vec2(.5);
    vec2 uvc = (uv - vec2(.5));
    float time = uniforms.time * 4.;

    // Setup Camera
    CameraData cam = setupCamera(uvc);

    //Animate Camera
    animateCamera();

    // Scene Marching
    vec2 scenemarch = distmarch(cam.origin, cam.dir, DISTMARCH_MAXDIST);

    // Mouse Cursor
    vec2 mouse = (((uniforms.mouse.xy / uniforms.resolution) - vec2(.5)) * aspectRatio) + vec2(.5);
    float cursor = (1. - saturate(dot((uv - mouse) * 16., (uv - mouse) * 16.))) * (.5 * uniforms.mouse.z);
    col += vec3(cursor * .2);

    // Vignette
    col = mix(col, vec3(.157, .153, .169), dot(uvc * 2.5, uvc * 2.5));
    
    oColor = vec4(col, 1.0);
}