'use strict';
var libs = Object.create(null);
module.exports = libs;

libs['chrono'              ] = '';
libs['string'              ] = '\
#ifndef _STRING_ \n\
#define _STRING_ \n\
namespace std { \n\
class string {}; \n\
}\n\
#endif';
libs['vector'              ] = '';
libs['list'                ] = '';
libs['map'                 ] = '\
#ifndef _MAP_ \n\
#define _MAP_ \n\
namespace std { \n\
template<typename Key, typename Value> \n\
class map {}; \n\
}\n\
#endif';
libs['iostream'            ] = '';
libs['fstream'             ] = '\
#ifndef _fSTREAM_ \n\
#define _fSTREAM_ \n\
namespace std { \n\
class ofstream {}; \n\
}\n\
#endif';
libs['stdint.h'            ] = '\
typedef unsigned char uint8_t; \n\
';
libs['stdio.h'             ] = '';
libs['math.h'              ] = '';
libs['unistd.h'            ] = '';
libs['sys/time.h'          ] = 'struct timeval { long tv_sec; long tv_usec; };';

libs['Eigen/Core'          ] = '\
namespace Eigen { \n\
class Vector2f {}; \n\
class Vector3f {}; \n\
} \n\
';
libs['Eigen/StdVector'     ] = '\
#define EIGEN_DEFINE_STL_VECTOR_SPECIALIZATION(x) \n\
';
libs['opencv2/opencv.hpp'  ] = '\
namespace cv { \n\
class Mat {}; \n\
} \n\
';
libs['sophus/se3.h'        ] = '\
namespace Sophus {} \n\
';
libs['boost/shared_ptr.hpp'] = '\
namespace boost { \n\
template<class T> \n\
class shared_ptr{}; \n\
} \n\
';
