#include <cmath>
#include <iostream>
#include <limits>
#include <vector>

// Vec2

class Vec2 {
    public:
        float x, y;
        explicit Vec2(const float x = 0.0,
            const float y = 0.0) {this->x = x; this->y = y;}
        Vec2 operator+(const Vec2& v) const;
        Vec2 operator-(const Vec2& v) const;
        Vec2 operator*(const float a) const;
        Vec2 operator/(const float a) const;
        bool operator==(const Vec2& v) const;
        bool operator!=(const Vec2& v) const;
        bool IsZero();
        float DistanceSquared(const Vec2& v);
        float Distance(const Vec2& v);
        float DotProduct(const Vec2& v);
        float LengthSquared();
        float Length();
        Vec2 Normalize();
        Vec2 Extend(Vec2 const v, float dist);
};
//-----------------------------------------------------------------------------------------

Vec2 Vec2::operator+(const Vec2& v) const
{
    return Vec2(x + v.x, y + v.y);
}
//-----------------------------------------------------------------------------------------

Vec2 Vec2::operator-(const Vec2& v) const
{
    return Vec2(x - v.x, y - v.y);
}
//-----------------------------------------------------------------------------------------

Vec2 Vec2::operator*(const float a) const
{
    return Vec2(x * a, y * a);
}
//-----------------------------------------------------------------------------------------

Vec2 Vec2::operator/(const float a) const
{
    return Vec2(x / a, y / a);
}
//-----------------------------------------------------------------------------------------

bool Vec2::operator==(const Vec2& v) const
{
    return (x == v.x) && (y == v.y);
}
//-----------------------------------------------------------------------------------------

bool Vec2::operator!=(const Vec2& v) const
{
    return (x != v.x) || (y != v.y);
}
//-----------------------------------------------------------------------------------------

bool Vec2::IsZero()
{
    return (x == 0 && y == 0);
}
//-----------------------------------------------------------------------------------------

float Vec2::DistanceSquared(const Vec2& v)
{
    float dx = x - v.x, dy = y - v.y;
    return dx * dx + dy * dy;
}
//-----------------------------------------------------------------------------------------

float Vec2::Distance(const Vec2& v)
{
    return sqrtf(DistanceSquared(v));
}
//-----------------------------------------------------------------------------------------

float Vec2::DotProduct(const Vec2& v)
{
    return (x * v.x) + (y * v.y);
}
//-----------------------------------------------------------------------------------------

float Vec2::LengthSquared()
{
    return x * x + y * y;
}
//-----------------------------------------------------------------------------------------

float Vec2::Length()
{
    return sqrtf(LengthSquared());
}
//-----------------------------------------------------------------------------------------

Vec2 Vec2::Normalize()
{
    float l = Length();
    return Vec2(x / l, y / l);
}
//-----------------------------------------------------------------------------------------

Vec2 Vec2::Extend(const Vec2 v, float dist)
{
    Vec2 self = *this;
    if (dist == 0.0) return self;
    return self + (v - self).Normalize() * dist;
}

// Input & Output

struct PredictionInput
{
    int Speed;
    int Range;
    float Delay;
    int Radius;
    bool AddHitBox;
};

struct PredictionOutput
{
    Vec2 CastPos;
    Vec2 PredPos;
};

// Unit

struct Unit
{
    Vec2 Position;
    int BoundingRadius;
    int MovementSpeed;
    std::vector<Vec2> Paths;
};

// Prediction

class Prediction
{
    private:
        int GetPathIndex(std::vector<Vec2> path, Vec2 point);
        float Interception(const Vec2 startPos, const Vec2 endPos,
            const Vec2 source, int speed, int missileSpeed, float delay);
        std::vector<Vec2> CutWaypoints(std::vector<Vec2> waypoints, float dist);
        std::vector<Vec2> GetWaypoints(Unit unit);
    public:
        PredictionOutput PredictPosition(Vec2 source, Unit unit, PredictionInput input);
};
//-----------------------------------------------------------------------------------------

int Prediction::GetPathIndex(std::vector<Vec2> path, Vec2 point)
{
	// find the shortest distance between main point
	// and the closest point on each path segment
    int index = 0;
    float distance = std::numeric_limits<float>::infinity();
    for (int i = 0; i < path.size() - 1; i++)
    {
        Vec2 a = path[i], b = path[i + 1];
        Vec2 ap = point - a, ab = b - a;
        float t = ap.DotProduct(ab) / ab.LengthSquared();
        Vec2 pt = t < 0.0 ? a : (t > 1.0 ? b : (a + ab * t));
        float dist = point.DistanceSquared(pt);
        if (dist < distance) {distance = dist; index = i + 1;}
    }
    return index;
}
//-----------------------------------------------------------------------------------------

float Prediction::Interception(const Vec2 startPos, const Vec2 endPos,
    const Vec2 source, int speed, int missileSpeed, float delay = 0.0)
{
    // dynamic circle-circle collision
	// https://ericleong.me/research/circle-circle/
    Vec2 dir = endPos - startPos;
    float magn = dir.Length();
    Vec2 vel = dir * float(speed) / magn;
    dir = startPos - source;
    float a = vel.LengthSquared() - missileSpeed * missileSpeed;
    float b = 2.0 * vel.DotProduct(dir);
    float c = dir.LengthSquared();
    float delta = b * b - 4.0 * a * c;
    if (delta >= 0.0) // at least one solution exists
    {
        delta = sqrtf(delta);
        float t1 = (-b + delta) / (2.0 * a),
            t2 = (-b - delta) / (2.0 * a);
        float t = 0.0;
        if (t2 >= delay)
            t = (t1 >= delay) ?
                fmin(t1, t2) : fmax(t1, t2);
        return t; // the final solution
    }
    return 0.0; // no solutions found
}
//-----------------------------------------------------------------------------------------

std::vector<Vec2> Prediction::CutWaypoints(std::vector<Vec2> waypoints, float dist)
{
	// cut the path at the given distance and return the remaining points
    if (dist < 0)
    {
		// if the distance is negative, extend the first segment
        waypoints[0] = waypoints[0].Extend(waypoints[1], dist);
        return waypoints;
    }
    std::vector<Vec2> result;
    float distance = dist;
    int size = waypoints.size();
    for (int i = 0; i < size - 1; i++)
    {
        float d = waypoints[i].Distance(waypoints[i + 1]);
        if (d > distance)
        {
			// found!
            result.push_back(waypoints[i].Extend(
                waypoints[i + 1], distance));
            for (int j = i + 1; j < size; j++)
                result.push_back(waypoints[j]);
            break;
        }
        distance -= d;
    }
    if (result.size() > 0) return result;
	// if the given distance is longer than path length,
	// then return the vector with last waypoint
    result.push_back(waypoints.back());
    return result;
}
//-----------------------------------------------------------------------------------------

std::vector<Vec2> Prediction::GetWaypoints(Unit unit)
{
	// we got the complete unit's path, but we need to find on which segment he's currently
	// on, just to predict the current situation (not the situation that already passed)
    std::vector<Vec2> result;
	// obviously the first waypoint is his position
    result.push_back(unit.Position);
    int size = unit.Paths.size();
    if (size <= 1) // unit is standing
        return result;
    else if (size == 2) // unit has one moving path
    {
        result.push_back(unit.Paths[1]);
        return result;
    }
	// unit has multi-segment moving path find the index of
	// segment where he's currently on and continue getting waypoints...
    for (int i = GetPathIndex(unit.Paths, result[0]); i < size; i++)
        result.push_back(unit.Paths[i]);
    return result;
}
//-----------------------------------------------------------------------------------------

PredictionOutput Prediction::PredictPosition(Vec2 source, Unit unit, PredictionInput input)
{
    PredictionOutput output;
    output.CastPos = Vec2();
    output.PredPos = Vec2();
	// need some more checks like IsValid etc...
    if (source.IsZero()) return output;
    std::vector<Vec2> waypoints = GetWaypoints(unit);
	// calculate max boundary offset for cast position
	int offset = input.Radius +
        (input.AddHitBox ? unit.BoundingRadius : 0);
    if (input.Speed == 0 || input.Speed >= 9999)
    {
		// our spell isn't a missile, so we cut waypoints based on
		// delay and movement speed, then we return the first point
        float threshold = input.Delay * unit.MovementSpeed;
        output.CastPos = CutWaypoints(waypoints, threshold - offset)[0];
        output.PredPos = CutWaypoints(waypoints, threshold)[0];
        return output;
    }
	// predict the unit path when spell windup already completed;
	// we subtract the offset this time - just in case if unit is going
	// to complete the path we'll have perfectly calculated positions;
	// run the drawing simulation, then you'll see what i mean ;)
    waypoints = CutWaypoints(waypoints,
        input.Delay * unit.MovementSpeed - offset);
	// here is the part for handling dynamic prediction
	// for each path segment we calculate interception time
    float totalTime = 0;
    for (int i = 0; i < waypoints.size() - 1; i++)
    {
        Vec2 a = waypoints[i], b = waypoints[i + 1];
        float tB = a.Distance(b) / unit.MovementSpeed;
        a = a.Extend(b, -unit.MovementSpeed * totalTime);
        float t = Interception(a, b, source,
            unit.MovementSpeed, input.Speed, totalTime);
        if (t > 0 && t >= totalTime && t <= totalTime + tB)
        {
			// interception time is valid, we found the solution
            float threshold = t * unit.MovementSpeed;
            output.CastPos = CutWaypoints(waypoints, threshold)[0];
            output.PredPos = CutWaypoints(waypoints, threshold + offset)[0];
            return output;
        }
		// if any segment didn't pass the test, we add unit's arrival
		// time on segment to the total time and use it for further tests
        totalTime += tB;
    }
	// no solution found, so unit is completing his path...
    Vec2 pos = waypoints.back();
    output.CastPos = pos;
    output.PredPos = pos;
    return output;
}
//-----------------------------------------------------------------------------------------

int main()
{
    PredictionInput pI;
    pI.Speed = 20;
    pI.Range = 10;
    pI.Delay = 0.25;
    pI.Radius = 5;
    pI.AddHitBox = false;

    Vec2 s = Vec2(150, -20);

    Unit u;
    u.Position = Vec2(70, 30);
    u.BoundingRadius = 5;
    u.MovementSpeed = 30;
    u.Paths.push_back(Vec2(50, 50));
    u.Paths.push_back(Vec2(100, 0));
    u.Paths.push_back(Vec2(150, 50));

    PredictionOutput pO = Prediction().PredictPosition(s, u, pI);
    std::cout << pO.PredPos.x << " " << pO.PredPos.y << std::endl;
    std::cout << pO.CastPos.x << " " << pO.CastPos.y << std::endl;
}
