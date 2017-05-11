//
//  ViewController.m
//  OpenGLES-3.3纹理
//
//  Created by ShiWen on 2017/5/11.
//  Copyright © 2017年 ShiWen. All rights reserved.
//

#import "ViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKContext.h" 

@interface GLKEffectPropertyTexture (AGLKAddDitions)
- (void)aglkSetParameter:(GLenum)parameterID
                   value:(GLint)value;
@end
@implementation GLKEffectPropertyTexture (AGLKAddDitions)

- (void)aglkSetParameter:(GLenum)parameterID value:(GLint)value;
{
    glBindTexture(self.target, self.name);
    
    glTexParameteri(self.target,parameterID,value);
}

@end
typedef struct {
    GLKVector3 postionCorrds;
    GLKVector2 texCorrds;
}Scens;

static  Scens vertexs[] = {
    {{-0.5f,-0.5f,0.0f},{0.0f,0.0f}},
    {{-0.5f,0.5f,0.0f},{0.0f,1.0f}},
    {{0.5f,-0.5f,0.0f},{1.0f,0.0f}},
    
    {{0.5f,0.5f,0.0f},{1.0f,1.0f}},
    {{0.5f,-0.5f,0.0f},{1.0f,0.0f}},
    {{-0.5f,0.5f,0.0f,},{0.0f,1.0f}},
};
//默认数据，在重置时候使用
static const Scens defaultVertexs[]={
    {{-0.3f,-0.3f,0.0f},{0.0f,0.0f}},//第三象限
    {{-0.3f,0.3f,0.0f},{0.0f,1.0f}},//第二象限
    {{0.3f,-0.3f,0.0f},{1.0f,0.0f}},//第四象限
    
    {{0.3f,0.3f,0.0f},{1.0f,1.0f}},//第一象限
    {{0.3f,-0.3f,0.0f},{1.0f,0.0f}},//第四象限
    {{-0.3f,0.3f,0.0f,},{0.0f,1.0f}},//第二象限
};
static GLKVector3 moveVectors[6] = {
    {-0.02f,  -0.01f, 0.01f},
    {0.01f,  -0.005f, -0.05f},
    {-0.01f,   0.01f, 0.01f},
    
    {0.02f,  0.01f, 0.05f},
    {-0.01f,  0.005f, -0.01f},
    {0.01f,   -0.01f, -0.01f},
};

@interface ViewController ()<GLKViewControllerDelegate>
@property (strong ,nonatomic) GLKBaseEffect *mBaseEffect;
@property (strong ,nonatomic) AGLKVertexAttribArrayBuffer *vertexBuffer;
//纹理是否失真
@property (nonatomic,assign) BOOL isDistortion;
//纹理是否重复
@property (nonatomic,assign) BOOL isRepeat;
//是否播放动画
@property (nonatomic,assign) BOOL isAnimation;
@property (nonatomic,assign) float vertexSlider;




@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupConfig];
}

-(void)setupConfig{
    self.delegate = self;
    self.preferredFramesPerSecond = 60;
    
    GLKView *view = (GLKView *)self.view;
    view.context = [[AGLKContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
//
    [AGLKContext setCurrentContext:view.context];
//
//    
    self.mBaseEffect = [[GLKBaseEffect alloc] init];
    self.mBaseEffect.useConstantColor = GL_TRUE;
    self.mBaseEffect.constantColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    [((AGLKContext*)view.context) setClearColor:GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f) ];
    self.vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                         initWithAttribStride:sizeof(Scens)
                         numberOfVertices:sizeof(vertexs)/sizeof(Scens) bytes:vertexs usage:GL_DYNAMIC_DRAW];
//    //设置纹理
    CGImageRef imageRef = [[UIImage imageNamed:@"test.png"] CGImage];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *texTureInfo = [GLKTextureLoader textureWithCGImage:imageRef options:options error:nil];
    self.mBaseEffect.texture2d0.target = texTureInfo.target;
    self.mBaseEffect.texture2d0.name = texTureInfo.name;
    
}

/**
 若实现了update方法，则该方法不调用
 */
-(void)glkViewControllerUpdate:(GLKViewController *)controller{
    NSLog(@"更新");
    [self animationAction];
    [self distortionChange];
    [self.vertexBuffer reinitWithAttribStride:sizeof(Scens) numberOfVertices:sizeof(vertexs)/sizeof(Scens) bytes:vertexs];
}
//-(void)update{
//    NSLog(@"更新");
//    [self animationAction];
//    [self distortionChange];
//    [self.vertexBuffer reinitWithAttribStride:sizeof(Scens) numberOfVertices:sizeof(vertexs)/sizeof(Scens) bytes:vertexs];
//}
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    [self.mBaseEffect prepareToDraw];
    [((AGLKContext*)view.context) clear:GL_COLOR_BUFFER_BIT];
    [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:offsetof(Scens, postionCorrds) shouldEnable:YES];
    [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0 numberOfCoordinates:2 attribOffset:offsetof(Scens, texCorrds) shouldEnable:YES];
    [self.vertexBuffer drawArrayWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:6];
}

- (IBAction)switchChange:(UISwitch *)sender {
    self.isDistortion = [sender isOn];
}
-(void)distortionChange{
    
    /**
     纹理是否失真设置
     */
    [self.mBaseEffect.texture2d0 aglkSetParameter:GL_TEXTURE_MAG_FILTER value:(self.isDistortion?GL_LINEAR:GL_NEAREST)];
    
    /**
     纹理是否重复设置
     */
    [self.mBaseEffect.texture2d0 aglkSetParameter:GL_TEXTURE_WRAP_S value:(self.isRepeat? GL_REPEAT : GL_CLAMP_TO_EDGE)];
}

- (IBAction)repeatTexture:(UISwitch *)sender {
    self.isRepeat = [sender isOn];
}
- (IBAction)animation:(UISwitch *)sender {
    self.isAnimation = [sender isOn];
}
- (IBAction)textureMove:(UISlider *)sender {
    self.vertexSlider = sender.value;
}
-(void)animationAction{
    if (self.isAnimation) {
        //开始动画
        for (int i = 0; i<6; i++) {
            vertexs[i].postionCorrds.x += moveVectors[i].x;
            if (vertexs[i].postionCorrds.x >= 1.0f || vertexs[i].postionCorrds.x <= -1.0f) {
                moveVectors[i].x = -moveVectors[i].x;
            }
            vertexs[i].postionCorrds.y += moveVectors[i].y;
            if (vertexs[i].postionCorrds.y >= 1.0f || vertexs[i].postionCorrds.y <= -1.0f) {
                moveVectors[i].y = -moveVectors[i].y;
            }
            vertexs[i].postionCorrds.z += moveVectors[i].z;
            if(vertexs[i].postionCorrds.z >= 1.0f ||
               vertexs[i].postionCorrds.z <= -1.0f)
            {
                moveVectors[i].z = -moveVectors[i].z;
            }
        }
    }else{
        //结束动画
        for (int i = 0; i < 6; i++) {
            vertexs[i].postionCorrds.x = defaultVertexs[i].postionCorrds.x;
            vertexs[i].postionCorrds.y = defaultVertexs[i].postionCorrds.y;
            vertexs[i].postionCorrds.z = defaultVertexs[i].postionCorrds.z;
        }
    }
    for (int i = 0 ; i< 6; i++) {
        vertexs[i].texCorrds.x = defaultVertexs[i].texCorrds.x+self.vertexSlider;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
