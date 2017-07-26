#include <libraw.h>

extern "C" {
char const * make(libraw_data_t *x) { return x->idata.make; }
char const * model(libraw_data_t *x) { return x->idata.model; }
char const * cdesc(libraw_data_t *x) { return x->idata.cdesc; }
int64_t raw_width(libraw_data_t *x) { return x->sizes.raw_width; }
int64_t raw_height(libraw_data_t *x) { return x->sizes.raw_height; }
int64_t width(libraw_data_t *x) { return x->sizes.width; }
int64_t height(libraw_data_t *x) { return x->sizes.height; }
int64_t iwidth(libraw_data_t *x) { return x->sizes.iwidth; }
int64_t iheight(libraw_data_t *x) { return x->sizes.iheight; }
double iso_speed(libraw_data_t *x) { return x->other.iso_speed; }
double shutter(libraw_data_t *x) { return x->other.shutter; }
double aperture(libraw_data_t *x) { return x->other.aperture; }
double focal_length(libraw_data_t *x) { return x->other.focal_len; }
unsigned short* image(libraw_data_t *x) { return &(x->image[0][0]); }
}
