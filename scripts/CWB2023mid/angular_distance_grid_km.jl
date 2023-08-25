

using SphericalGeometry

# The distance in kilometer of two cell with 0.1 degree difference in Latitude is:
twopoints = SphericalGeometry.Point.(
    [24.2, 24.3],
    [121.0, 121.0],
)
angular_distance(twopoints...) * 6371 / 360 * 2π

# Verified with matlab code: `deg2km(distance('gc', [24.2, 121.0], [24.3, 121.0]))`
