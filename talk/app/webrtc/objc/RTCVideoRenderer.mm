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

#import "RTCVideoRenderer+internal.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "RTCI420Frame.h"
#import "RTCVideoRendererDelegate.h"
#include "talk/media/base/videoframe.h"
#include "webrtc/modules/video_render/video_render_impl.h"
#include "webrtc/common_video/interface/i420_video_frame.h"
#include "talk/app/webrtc/mediastreaminterface.h"
#include "webrtc/modules/video_render/ios/video_render_ios_view.h"
#include "webrtc/modules/video_render/ios/video_render_ios_impl.h"

// Adapter presenting a webrtc::VideoRenderCallback as a
// webrtc::VideoRendererInterface.
// Thanks to https://groups.google.com/d/msg/discuss-webrtc/M2LA4_6Z6a4/l0FqRztIKrcJ
class CallbackConverter : public webrtc::VideoRendererInterface {
public:
    CallbackConverter(webrtc::VideoRenderCallback *callback, const uint32_t streamId) : callback_(callback), streamId_(streamId) {}
    
    virtual void SetSize(int width, int height) { };

    virtual void RenderFrame(const cricket::VideoFrame* frame) {
        
        assert(callback_ != NULL);
        
        //Make this into an I420VideoFrame
        
        assert(frame != NULL);
        
        size_t width = frame->GetWidth();
        size_t height = frame->GetHeight();
        
        size_t y_plane_size = width * height;
        size_t uv_plane_size = frame->GetChromaSize();
        
        webrtc::I420VideoFrame *i420Frame = new webrtc::I420VideoFrame();
        i420Frame->CreateFrame(
                               y_plane_size, frame->GetYPlane(),
                               uv_plane_size, frame->GetUPlane(),
                               uv_plane_size, frame->GetVPlane(),
                               width, height,
                               frame->GetYPitch(), frame->GetUPitch(), frame->GetVPitch());
        
        i420Frame->set_render_time_ms(frame->GetTimeStamp() / 1000000);
        
        callback_->RenderFrame(streamId_, *i420Frame);
        
        delete i420Frame;
    }
    
private:
    webrtc::VideoRenderCallback *callback_;
    const uint32_t streamId_;
};

@implementation RTCVideoRenderer

webrtc::VideoRendererInterface *_videoRenderer;

+ (UIView *) renderViewWithFrame:(CGRect)frame {
    
    VideoRenderIosView *renderView = [[VideoRenderIosView alloc] initWithFrame:frame];
    [renderView setBackgroundColor:[UIColor blackColor]];
    
    return renderView;
    
}

+ (RTCVideoRenderer *)videoRenderInView:(UIView *)renderView forEndpointWithId:(NSInteger)endpointId {
    
    // Create a render module
    webrtc::VideoRender *renderModule = webrtc::VideoRender::CreateVideoRender(endpointId, (void*)CFBridgingRetain(renderView), false, webrtc::kRenderiOS);
    assert(renderModule != NULL);
    
    const int streamId0 = endpointId;
    webrtc::VideoRenderCallback *renderCallback = renderModule->AddIncomingRenderStream(streamId0, endpointId, 0.0f, 0.0f, 1.0f, 1.0f);
    assert(renderCallback != NULL);
    
    int error = 0;
    error = renderModule->StartRender(streamId0);
    assert(error == 0);
    
    // Create a new VideoRendererInterface
    webrtc::VideoRendererInterface* interface = new CallbackConverter(renderCallback, endpointId);
    assert(interface != NULL);

    // Init an instance of RTCVideoRenderer with the video render interface
    RTCVideoRenderer *renderer = [[RTCVideoRenderer alloc] initWithVideoRenderer:interface];

    return renderer;
    
}

- (id)initWithDelegate:(id<RTCVideoRendererDelegate>)delegate {
  if ((self = [super init])) {
    _delegate = delegate;
    // TODO (hughv): Create video renderer.
  }
  return self;
}

@end

@implementation RTCVideoRenderer (Internal)

- (id)initWithVideoRenderer:(webrtc::VideoRendererInterface *)videoRenderer {
  if ((self = [super init])) {
      _videoRenderer = videoRenderer;
  }
  return self;
}

- (webrtc::VideoRendererInterface *)videoRenderer {
    return _videoRenderer;
}

@end
