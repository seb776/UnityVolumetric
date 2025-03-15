// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
float4 mod289(float4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
float4 perm(float4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(float3 p){
    float3 a = floor(p);
    float3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    float4 b = a.xxyy + float4(0.0, 1.0, 0.0, 1.0);
    float4 k1 = perm(b.xyxy);
    float4 k2 = perm(k1.xyxy + b.zzww);

    float4 c = k2 + a.zzzz;
    float4 k3 = perm(c);
    float4 k4 = perm(c + 1.0);

    float4 o1 = frac(k3 * (1.0 / 41.0));
    float4 o2 = frac(k4 * (1.0 / 41.0));

    float4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    float2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

// https://gamedev.stackexchange.com/questions/18436/most-efficient-aabb-vs-ray-collision-algorithms
bool Raytracing_line_box(float3 origin, float3 rayDir, float3 extents, out float tmin, out float tmax)
{
	float3 lb = -extents*0.5;
	float3 rt = extents*0.5;
	float3 dirfrac = 0.;
	// rayDir is unit direction vector of ray
dirfrac.x = 1.0f / rayDir.x;
dirfrac.y = 1.0f / rayDir.y;
dirfrac.z = 1.0f / rayDir.z;
// lb is the corner of AABB with minimal coordinates - left bottom, rt is maximal corner
// origin is origin of ray
float t1 = (lb.x - origin.x)*dirfrac.x;
float t2 = (rt.x - origin.x)*dirfrac.x;
float t3 = (lb.y - origin.y)*dirfrac.y;
float t4 = (rt.y - origin.y)*dirfrac.y;
float t5 = (lb.z - origin.z)*dirfrac.z;
float t6 = (rt.z - origin.z)*dirfrac.z;

tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6));
tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6));

float t = 0.;
// if tmax < 0, ray (line) is intersecting AABB, but the whole AABB is behind us
if (tmax < 0)
{
    t = tmax;
    return false;
}

// if tmin > tmax, ray doesn't intersect AABB
if (tmin > tmax)
{
    t = tmax;
    return false;
}

t = tmin;
return true;
}

float sampleDensity(float3 p)
{
	return saturate((noise(p+float3(_Time.y, 0., 0.))+ noise(p * 2.))/2.-.4);
}

void ProcessClouds_float(float4 inputCol, float depth, float3 cameraPosWS, float3 viewDirWS, float3 cloudBoxPosition, float3 cloudBoxScale,  out float3 outputCol)
{
	viewDirWS = -viewDirWS;
	float tmin = 0.;
	float tmax = 0.;
	if (Raytracing_line_box(cameraPosWS-cloudBoxPosition, viewDirWS, cloudBoxScale, tmin, tmax) && tmin < depth)
	{
		float3 color = inputCol.xyz;
		float3 startPos = cameraPosWS;
		if (tmin > 0.)
			startPos = cameraPosWS + viewDirWS * tmin;

		float3 endPos = cameraPosWS + viewDirWS * tmax;
		float3 p = startPos + viewDirWS * noise(startPos*1000.+_Time.y)*.5; // Random offset to smoothen raymarching artifact
		const float iterationCount = 32.;
		const float stepSize = distance(startPos, endPos) / iterationCount;
		for (float i = 0.; i < iterationCount && distance(cameraPosWS, p) < depth; ++i)
		{
			float density = sampleDensity(p);
			color = lerp(color, .5, pow(density, 1.5));
			p += viewDirWS * stepSize;
		}
		outputCol = color;
	}
	else 
	{
		outputCol = inputCol.xyz;
	}
	
	//outputCol = depth / 10.;
}