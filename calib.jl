using AprilTags, Images, CoordinateTransformations, StaticArrays, GLMakie, ImageTransformations, FreeTypeAbstraction, ImageView

detector = AprilTagDetector()
image = load("img.jpg");
tags = detector(image)
for tag in tags
  drawTagBox!(image, tag)
end
imshow(image) # only 7 of the 8 got detected, which should be fine and is understandable because the 4th tag suffered from a lot of reflection

sort!(tags, by = x -> x.id) # I reckon this is not needed
moving = [t.c for t in tags]
angular_offset = deg2rad(5) # from the polar grid painted on the arena
radius = 1000 + 38.1/2 # of the circle drawn on the arena + half the size of the printed apriltag
θs = [(t.id - 1)*2π/8 + angular_offset for t in tags] # polar angles for each tag
fixed = CartesianFromPolar().(Polar.(radius, θs))

function createAffineMap(fixed, moving) # works for a set of 3 fixed and moving coordinates
  X = ones(length(moving), 3)
  for (i,xy) in enumerate(moving)
    X[i,1:2] .= xy
  end
  Y = reduce(hcat, fixed)'
  c = (X \ Y)'
  A = c[:, 1:2]
  b = c[:, 3]
  AffineMap(SMatrix{2,2,Float64}(A), SVector{2, Float64}(b))
end

i = [2, 4, 7] # I chose 3 arbitrary points
tform = createAffineMap(fixed[i], moving[i])
@assert fixed[i] ≈ tform.(moving[i]) # works!

text([string(t.id) for t in tags], position = Point2f0.(fixed), axis = (aspect = DataAspect(),))
scatter!(Point2f0.(fixed))
m2 = tform.(moving) # apply transform to the rest of the points
scatter!(Point2f0.(m2), marker = '∘', fontsize = 10) # ooof, the transform didn't work at all for the rest of the points

imgw = warp(image, inv(tform))
imshow(imgw) # and indeed the painted circle is not circular at all

