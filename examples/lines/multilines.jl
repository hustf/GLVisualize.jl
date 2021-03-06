using GLAbstraction, Colors, GeometryTypes, GLVisualize, Reactive

if !isdefined(:runtests) # We use the examples to generate docs and tests
    window = glscreen()
end

vx = -10:0.1:10;
vy = -8:0.1:8;
x = [i for i in vx, j in vy];
y = [j for i in vx, j in vy];
#x,y = meshgrid(vx, vy)
z = (x .* y .* (x.^2 - y.^2) ./ (x.^2 .+ y.^2 + eps())) / 5.;
xyz  = map(Point3f0, zip(x, y, z));
# ma
lines3d = visualize(
	xyz, :lines,
	color=RGBA(0.0f0,0.74736935f0,1.0f0,0.6f0),
	thickness=4f0
)
_view(lines3d, window, camera=:perspective)

if !isdefined(:runtests)
    @async renderloop(window)
end
