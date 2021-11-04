using AprilTags, Images, CoordinateTransformations, ImageTransformations, FreeTypeAbstraction, ImageView, LinearAlgebra

detector = AprilTagDetector()
img = load("one.jpg") # an image with just one tag

tag = only(detector(img)) # get the only one tag
drawTagBox!(img, tag)
imshow(img) 

push1(x) = [x; 1] # convinience function

corners = [[round.(reverse(sincos(θ)))...] for θ in 3π/4:-π/2:-3π/4] # generate the coordinates of the tag in real world coordinates

# no scale
H = LinearMap(tag.H) # use the homography matrix as a transformation matrix
itform = PerspectiveMap() ∘ H ∘ push1 # this is the inverse transform
tform =  PerspectiveMap() ∘ inv(H) ∘ push1 # this is the transform
@assert all(isapprox.(tform.(tag.p), corners, atol = 1)) # test by transforming the tag's corners from pixel coordinates to world coordinates
@assert all(isapprox.(itform.(corners), tag.p, atol = 1)) # and test by inverse transforming the world coordinates of the corners to image coordinates
imgw = warp(img, itform, ImageTransformations.autorange(img, tform)) # warp the image
imshow(imgw) # first obvious problem is the scaling


# with scale
s = 200 # a scale of 200 folds
corners .*= s # adjust by the new scale
scale = LinearMap(s*I) # scaling transforms
iscale = LinearMap(I/s) 
itform = PerspectiveMap() ∘ H ∘ push1 ∘ iscale # add the scaling to the transformation pipelines
tform =  scale ∘ PerspectiveMap() ∘ inv(H) ∘ push1
@assert all(isapprox.(tform.(tag.p), corners, atol = 1)) # testing worked
@assert all(isapprox.(itform.(corners), tag.p, atol = 1))
imgw = warp(img, itform, ImageTransformations.autorange(img, tform)) # nice, the image size more useful
imshow(imgw) # but the rectification is wrong!?


