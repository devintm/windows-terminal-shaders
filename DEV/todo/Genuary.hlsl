// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

#define sat(a) clamp(a, 0., 1.)
mat2 r2d(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

vec2 _min(vec2 a, vec2 b)
{
    if(a.x < b.x)
        return a;
    return b;
}

vec2 map(vec3 p)
{
    p.xy *= r2d(.25);
        p.xz *= r2d(.25);

    p -= vec3(1.,1.2,0.);
    vec2 acc = vec2(10000.,-1.);
    float shape = length(p)-1.;
    shape = max(shape, -(length(p.xy)-.5));
    shape = max(shape, -(length(p)-.8));
    float mat = 0.0;
    if (length(p) > .9)
    {
        mat = 1.;
        float th = 0.04;
        if (abs(length(p.xz)-.2)-th < 0.)
            mat = 3.;
        if (abs(length(p.yz)-.2)-th < 0.)
            mat = 3.;
    }
       
    if (length(p.xy) < .51)
        mat = 2.;

        
    acc = _min(acc, vec2(shape, mat));
    
    float antena = max(max(length(p.xz)-.015, p.y+.5), -p.y-2.);
    antena = min(antena, length(p-vec3(0.,-2.,0.))-.1);
    acc = _min(acc, vec2(antena, 0.));
    return acc;
}

float grass(vec2 uv)
{
    uv.x+= sin(uv.y*20.+iTime)*.02;
    float h= mix(.01,.02, sat(sin(uv.x)*.5+.5));
    return uv.y-h*asin(sin(uv.x*250.+sin(uv.y*2.)*20.+sat(3.+uv.y*15.)*iTime));
}

vec3 getCam(vec3 rd, vec2 uv)
{
    vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
    vec3 u = normalize(cross(rd, r));
    return normalize(rd+r*uv.x+u*uv.y);
}

vec3 getNorm(vec3 p, float d)
{
  vec2 e = vec2(0.01,0.);
  return normalize(vec3(d)-vec3(map(p-e.xyy).x,map(p-e.yxy).x,map(p-e.yyx).x));
}
vec3 trace(vec3 ro, vec3 rd, int steps)
{
  vec3 p = ro;
  for (int i = 0; i<steps;++i)
  {
    vec2 res = map(p);
    if (res.x<0.01)
      return vec3(res.x,distance(p,ro),res.y);
    p+= rd*res.x;
  }
  return vec3(-1.);
}

vec3 rdr(vec2 uv)
{
    vec2 buv = uv;
    float baseT = iTime*.1;
    float t = sin(baseT)*.5;
    vec3 col = mix(vec3(0.694,0.827,0.824), vec3(0.796,0.882,0.871), sat(-uv.y));
    
    float xA = uv.x+t*.125;
    float mountA = uv.y+.1-0.05*sin(xA*5.)+0.01*asin(sin(xA*10.));
    vec3 mountACol = mix(vec3(0.627,0.710,0.690)*.8, vec3(0.702,0.784,0.765), sat(sin(14.6*length(vec2(xA,uv.y)-vec2(0.2,1.))*10.)*sin(length(vec2(xA,uv.y)-vec2(0.,1.))*50.)*1000.));
    col = mix(col, mountACol, 1.-sat(mountA*40000.));
    float xB = uv.x+t*.25;
    float mountB = uv.y+.1-0.02*sin(xB*10.)+0.01*asin(sin(xB*10.));
    col = mix(col, vec3(0.729,0.553,0.541), 1.-sat(mountB*40000.));
    
    vec3 ro = vec3(sin(t)*10.,0.,10.*cos(t));
    vec3 ta = vec3(t*4.,0.,0.);
    vec3 rd = normalize(ta-ro);
    
    rd = getCam(rd, buv);
    
    vec3 res = trace(ro, rd, 128);
    
    if (res.y > 0.)
    {
        vec3 p = ro+rd*res.y;
        vec3 n = getNorm(p, res.x);
        vec3 ldir = normalize(vec3(1.,-1.,1.));
        
        col = n*.5+.5;
        if (res.z == 0.)
            col = vec3(.1);
        if (res.z == 1. || res.z == 3.)
            col = mix(vec3(.8), vec3(.92), sat(dot(n,ldir)*100.));
        if (res.z == 2.)
            col = vec3(.4);
        if (res.z == 3.)
            col *= .75;
    }
    
    
    float xC = uv.x+t*.5;
    float mountC = uv.y+.15-0.02*sin(xC*7.)+0.01*asin(sin(xC*10.));
    col = mix(col, vec3(0.824,0.392,0.388), 1.-sat(mountC*40000.));
    

    float xD = uv.x+t;
    float mountD = uv.y+.17-0.02*sin(-xD*10.+4.)+0.015*asin(sin(xD*7.));
    mountD += .2+grass(uv);
    col = mix(col, vec3(0.776,0.314,0.314), 1.-sat(mountD*40000.));
    float xE = uv.x+t*2.;
    float mountE = uv.y+.3-0.04*sin(-xE*10.+4.)+0.015*asin(sin(xE*7.));
    mountE += .2+grass(uv);
    col = mix(col, vec3(0.541,0.173,0.173), 1.-sat(mountE*40000.));
    uv.y -= .2;
    float xCloud = uv.x+t*.0125;
    float cloud =  max(uv.y-asin(sin(xCloud*5.))*.02-sin(xCloud*5.-iTime*.25)*.03, -(uv.y+.03-.02*(sin(xCloud*5.+iTime*.25))));
    
    col = mix(col, vec3(0.776,0.875,0.863), 1.-sat(cloud*40000.));
    
    //col = vec3(1.)*sat(*40000.);
//    float t3d = iTime*.1;

    
    return col;
}
 
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.xx;
    float stp = .005;
    
    uv = floor(uv/stp)*stp;
    vec3 col = rdr(uv);
    
    fragColor = vec4(col,1.0);
}