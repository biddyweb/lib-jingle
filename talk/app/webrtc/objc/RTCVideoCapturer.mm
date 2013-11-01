/*
 * libjingle
 * Copyright 2013, Google Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "RTCVideoCapturer+internal.h"

#include "talk/media/base/videocapturer.h"
#include "talk/media/devices/devicemanager.h"
#include "webrtc/modules/video_capture/ios/video_capture_ios.h"

#if defined(HAVE_WEBRTC_VIDEO)
#include "talk/media/webrtc/webrtcvideocapturer.h"
#include "webrtc/modules/video_capture/ios/device_info_ios_objc.h"
#endif

@implementation RTCVideoCapturer {
  talk_base::scoped_ptr<cricket::VideoCapturer>_capturer;
}

+ (RTCVideoCapturer *)capturerWithDeviceName:(NSString *)deviceName {
    
    #if !defined(HAVE_WEBRTC_VIDEO)
        return nil;
    #endif
    
    // Create a video capturer module for iOS
    NSString *deviceAtIndexZero = [[DeviceInfoIosObjC captureDeviceForIndex:1] uniqueID];
    webrtc::VideoCaptureModule *capture_module = webrtc::videocapturemodule::VideoCaptureIos::Create(1, [deviceAtIndexZero UTF8String]);

    assert(capture_module != NULL);
    
    printf("Capture module exists");
    
    // Create a new WebRtcVideoCapturer
    cricket::WebRtcVideoCapturer* capturer = new cricket::WebRtcVideoCapturer;
    
    assert(capturer != NULL);

    // Init it with the module
    if (!capturer->Init(capture_module)) {
        printf("Failed to init capturer with module");
        return nil;
    }
    
    // Init RTCVideoCapturer with said capturer
    RTCVideoCapturer *rtcCapturer = [[RTCVideoCapturer alloc] initWithCapturer:capturer];
    
    // Return the object
    return rtcCapturer;

}

@end

@implementation RTCVideoCapturer (Internal)

- (id)initWithCapturer:(cricket::VideoCapturer *)capturer {
  if ((self = [super init])) {
    _capturer.reset(capturer);
  }
  return self;
}

// TODO(hughv):  When capturer is implemented, this needs to return
// _capturer.release() instead.  For now, this isn't used.
- (const talk_base::scoped_ptr<cricket::VideoCapturer> &)capturer {
  return _capturer;
}

@end
