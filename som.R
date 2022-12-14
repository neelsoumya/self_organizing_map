## Flexible Self-Organizing Maps in kohnonen 3.0

library("kohonen")
#if (packageDescription("kohonen")$Version < "3.0.6")
#ß  stop("Please upgrade the kohonen package")


##########################################################
## The three examples from the paper
##########################################################

##########################################################
## The pepper plant image example
##
## Demo presenting the image segmentation example of the pepper
## plant. Training the SOM for the pepper image takes some time, on my
## laptop approx 40 seconds.

library("kohonen")
library("RColorBrewer")

## function to plot the pepper picture
plot.picture <- function(dmat, what = c("col", "truth"),
                         image.dims = c(600, 800), mycols, ...) {
  what <- match.arg(what)

  if (what == "truth") { # dmat is a factor
    library("lattice")    
    if (missing(mycols)) {
      mycols <- brewer.pal(nlevels(dmat), "Set1")
    }
    myat <- 0:nlevels(dmat) + .5
    immat <- matrix(as.numeric(dmat), image.dims[1], image.dims[2])
    print(levelplot(t(immat)[, nrow(immat):1], at = myat,
                    colorkey = list(at = myat,
                                    space = "top",
                                    col = mycols,
                                    labels = list(at = myat[-1] - .5,
                                                  labels = levels(dmat))),
                    col.regions = mycols, xlab = "", ylab = "", ...))
   } else { # dmat is a matrix with columns "red", "green" and "blue"
    library("grid")
    immat <- rgb(dmat[, "red"], dmat[, "green"], dmat[, "blue"],
                 maxColorValue = 255)
    dim(immat) <- image.dims
    grid.raster(immat, interpolate = FALSE, ...)
  }
}

#######################################################################
## Image segmentation example

## Prepare input data
data("peppaPic", package = "kohonen")
X <- peppaPic[, c("red", "green", "blue")]
Y <- factor(peppaPic[, "truth"])
classes <- c("background", "leaves", "peppers", "peduncles", "stems",
             "sideshoots", "wires", "cuts")
levels(Y) <- classes
coords <- cbind(rep(1:800, each = 600), rep(1:600, 800))
colnames(coords) <- c("x", "y")

imdata <- list("rgb" = X, "truth" = Y, "coords" = coords)

## do segmentation
mygrid <- somgrid(4, 8, "hexagonal")
set.seed(15)
system.time(somsegm1 <- supersom(imdata, whatmap = c("rgb", "coords"),
                                 user.weights = c(1, 9),
                                 grid = mygrid))
## reconstruct the original image
reconstrIm <- predict(somsegm1, newdata = imdata)
X32 <- reconstrIm$predictions[["rgb"]]

plot.picture(X, x = unit(.025, "npc"),
             just = "left", width = unit(.45, "npc"))
plot.picture(X32, x = unit(.525, "npc"), 
             just = "left", width = unit(.45, "npc"))

## find class predictions for map units, concentrate only on peppers
## and leaves
truthpredictions <-
  classmat2classvec(reconstrIm$unit.predictions$truth)
trclasses <- levels(truthpredictions)
trclasses[!(trclasses %in% c("leaves", "peppers"))] <- "other"
levels(truthpredictions) <- trclasses
pepperunits <- which(truthpredictions == "peppers")

## visualize the rgb part of the map, using unit class labels as
## background colors
rgbpalette <- function(n) {
  if (n != 3) stop("Hey! Count again!")
  c("red", "green", "blue")
}
cluscolors <- brewer.pal(nlevels(truthpredictions), "Set3")
unitcols <- cluscolors[as.integer(truthpredictions)]
plot(somsegm1, "codes", whatmap = "rgb", bgcol = unitcols, 
     palette.name = rgbpalette, main = "")
## add unit numbers and a legend on top
idx <- (0:7)*4 + 1
text(somsegm1$grid$pts[idx, 1] - .5, somsegm1$grid$pts[idx, 2], 
     labels = idx, pos = 2)
add.cluster.boundaries(somsegm1, truthpredictions)
legend("top", legend = rev(levels(truthpredictions)), bty="n",
       pch = rep(21, 3), pt.bg = rev(cluscolors), ncol = 3)


