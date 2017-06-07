'use strict';
var libs = Object.create(null);
module.exports = libs;

libs['chrono'              ] = '';
libs['string'              ] = '';
libs['vector'              ] = '';
libs['list'                ] = '';
libs['map'                 ] = '';
libs['iostream'            ] = '';
libs['fstream'             ] = '';

libs['stdint.h'            ] = '';
libs['stdio.h'             ] = '';
libs['math.h'              ] = '';
libs['unistd.h'            ] = '';
libs['sys/time.h'          ] = 'struct timeval { long tv_sec; long tv_usec; };';

libs['Eigen/Core'          ] = '';
libs['Eigen/StdVector'     ] = '';
libs['opencv2/opencv.hpp'  ] = '';
libs['sophus/se3.h'        ] = '';
libs['boost/shared_ptr.hpp'] = '';
