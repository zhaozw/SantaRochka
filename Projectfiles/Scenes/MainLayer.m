//
//  MainLayer.m
//  SantaRochka
//
//  Created by  on 2012/1/22.
//  Copyright (c) 2012 Kawaz. All rights reserved.
//

#import "KWMusicManager.h"
#import "MainLayer.h"
#import "ResultLayer.h"
#define BACKGROUND_SPEED 1.5

@interface MainLayer()
- (void)onReady;
- (void)onGameStart;
- (void)onGameOver;
- (void)onCount;
- (void)onPresent;
@end

@implementation MainLayer

- (id)init {
  self.backgroundColor = ccc4(44, 28, 127, 255);
  self = [super init];
  if (self) {
    score_ = 0;
    interval_ = 2;
    isYes_ = NO;
    isTouched_ = YES;
    onGameOver_ = NO;
    mainLayer_ = [[CCLayer alloc] init];
    for(NSString* bgm in [NSArray arrayWithObjects:@"se1.caf", @"se2.caf", @"se3.caf", nil]){
      [[KWMusicManager sharedManager] preloadEffect:bgm];
    }
    [[KWMusicManager sharedManager] preloadBg:@"afternoon_lesson.caf"];
    CCLayer* bgLayer = [[CCLayer alloc] init];
    background_ = [KWScrollLayer layerWithFile:@"background.png"];
    background_.velocity = [KWVector vectorWithPoint:CGPointMake(BACKGROUND_SPEED, 0)];
    [bgLayer addChild:background_];
    
    [self addChild:bgLayer];
    
    CCSprite* frame = [CCSprite spriteWithFile:@"main_frame.png"];
    frame.position = CGPointMake(240, 165);
    
    
    CCSprite* rud = [CCSprite spriteWithAnimation:[CCAnimation animationWithTextureMap:[[CCTextureCache sharedTextureCache] addImage:@"rud.png"]
                                                                                  size:CGSizeMake(90, 70) 
                                                                                 delay:0.5]];
    rochka_ = [CCSprite spriteWithFile:@"rochka.png" rect:CGRectMake(0, 0, 112, 100)];
    
    CCSprite* bag = [CCSprite spriteWithFile:@"bag.png"];
    rochka_.position = CGPointMake(390, 175);
    rud.position = CGPointMake(45, 10);
    bag.position = CGPointMake(70, 15);
    
    CCParticleSystemQuad* shot = [CCParticleSystemQuad particleWithFile:@"shot.plist"];
    shot.position = ccp(75, 10);
    [rochka_ addChild:shot];
    
    [rochka_ addChild:rud];
    [rochka_ addChild:bag];
    [mainLayer_ addChild:rochka_];
    [self addChild:mainLayer_];
    [self addChild:frame];
    scoreLabel_ = [CCLabelTTF labelWithString:@"0" 
                                   dimensions:CGSizeMake(200, 50) 
                                    alignment:UITextAlignmentRight
                                     fontName:@"Marker Felt" 
                                     fontSize:24];
    scoreLabel_.position = ccp(330, 7);
    scoreLabel_.color = ccc3(20, 20, 20);
    [self addChild:scoreLabel_];
    [KKInput sharedInput].accelerometerActive = YES;
    self.isTouchEnabled = YES;
  }
  return self;
}

- (void)onEnterTransitionDidFinish {
  [[KWMusicManager sharedManager] playBgWithLoop:YES];
  [self onReady];
}

- (void)onReady {
  CCDirector* director = [CCDirector sharedDirector];
  CCSprite* ready = [CCSprite spriteWithFile:@"ready.png"];
  ready.position = CGPointMake(190, 250);
  ready.opacity = 0;
  CCParticleSystemQuad* particle = [CCParticleSystemQuad particleWithFile:@"particle.plist"];
  particle.position = ccp(0, director.screenSize.height / 2);
  __weak CCLayer* layer = mainLayer_;
  [particle runAction:[CCSequence actions:
                       [CCMoveTo actionWithDuration:10.0 position:CGPointMake(director.screenSize.width * 2,
                                                                             director.screenSize.height * 2)],
                       [CCCallBlockN actionWithBlock:^(CCNode* node){
    [layer removeChild:node cleanup:YES];
  }]
                       
                       ,nil]];
  [KWMusicManager sharedManager].bgVolume = 0.5;
  CCSequence* seq = [CCSequence actions:[CCFadeIn actionWithDuration:0.25], 
                     [CCDelayTime actionWithDuration:2], 
                     [CCFadeOut actionWithDuration:0.25],
                     [CCCallFunc actionWithTarget:self selector:@selector(onGameStart)],
                     nil];
  
  [ready runAction:seq];
  [mainLayer_ addChild:particle];
  [mainLayer_ addChild:ready];
  
  CCSprite* stage = [CCSprite spriteWithFile:@"stage1.png"];
  stage.position = CGPointMake(90, 120);
  stage.opacity = 0;
  [stage runAction:[CCFadeIn actionWithDuration:0.25]];
  [mainLayer_ addChild:stage];
}

- (void)onGameStart {
  timer_ = [KWTimer timerWithMax:interval_];
  timer_.looping = YES;
  [timer_ setOnCompleteListener:self selector:@selector(onCount)];
  [timer_ play];
  [KWMusicManager sharedManager].bgVolume = 1.0;
  [self onCount];
}

- (void)onGameOver {
  [timer_ stop];
  onGameOver_ = YES;
  CCSprite* jed = [CCSprite spriteWithAnimation:[CCAnimation animationWithTextureMap:[[CCTextureCache sharedTextureCache] addImage:@"jed.png"] 
                                                                                size:CGSizeMake(100.5, 126) 
                                                                               delay:0.3]];
  float x = rochka_.position.x;
  jed.position = CGPointMake(x, [CCDirector sharedDirector].screenSize.height);
  [mainLayer_ addChild:jed];
  [[KWMusicManager sharedManager] playEffect:@"se3.caf"];
  [rochka_ runAction:[CCMoveTo actionWithDuration:1.0 position:CGPointMake(x, -100)]];
  [[[KWMusicManager sharedManager] backgroundTrack] 
   fadeTo:0 
   duration:3.0f 
   target:nil 
   selector:nil];
  CCSequence* seq = [CCSequence actions:[CCMoveTo actionWithDuration:1.0 position:CGPointMake(x, -100)],
                     [CCDelayTime actionWithDuration:2],
                     [CCCallBlock actionWithBlock:^{
    ResultLayer* rl = [[ResultLayer alloc] initWithScore:score_];
    id scene = [[CCScene alloc] init];
    [scene addChild:rl];
    CCTransitionFade* transition = [CCTransitionFade transitionWithDuration:0.5f 
                                                                      scene:scene];
    [[CCDirector sharedDirector] replaceScene:transition];
  }], nil];
  [jed runAction:seq];
}

- (void)onCount {
  if (!isTouched_ && isYes_) {
    [self onGameOver];
    return;
  }
  [rochka_ removeChild:balloon_ cleanup:YES];
  KWRandom* rnd = [KWRandom random];
  int index = [rnd nextIntWithRange:NSMakeRange(0, 6)];
  isYes_ = index < 3;
  if (isYes_) {
    balloon_ = [CCSprite spriteWithFile:@"n_yes.png" 
                                   rect:CGRectMake(98 * index, 0, 98, 87)];
  } else {
    balloon_ = [CCSprite spriteWithFile:@"n_no.png" 
                                   rect:CGRectMake(98 * (index - 3), 0, 98, 87)];
  }
  balloon_.position = CGPointMake(-20, 100);
  [rochka_ addChild:balloon_];
  [[KWMusicManager sharedManager] playEffect:@"se1.caf"];
  isTouched_ = NO;
  interval_ = MAX(0.6, interval_ - 0.015);
  [timer_ set:interval_];
}

-(void)onPresent {
  [timer_ stop];
  [[KWMusicManager sharedManager] playEffect:@"se2.caf"];
  CCAnimation* anim = [CCAnimation animationWithTextureMap:[[CCTextureCache sharedTextureCache] addImage:@"rochka.png"]
                                                      size:CGSizeMake(112, 100) 
                                                     delay:0.10];
  __weak KWTimer* timer = timer_;
  __weak CCLayer* layer = mainLayer_;
  CCSprite* love = [CCSprite spriteWithFile:@"love.png"];
  love.position = ccp(balloon_.contentSize.width / 2, 
                      balloon_.contentSize.height / 2);
  [balloon_ addChild:love];
  id shoot = [CCCallBlockN actionWithBlock:^(CCNode* node){
    CCSprite* present = [CCSprite spriteWithFile:@"present.png"];
    present.position = node.position;
    id suicide = [CCCallBlockN actionWithBlock:^(CCNode* node) {
      [layer removeChild:node cleanup:YES];
    }];
    [present runAction:[CCSequence actionOne:[CCMoveTo actionWithDuration:1.0 
                                                                 position:CGPointMake(0, -100)] 
                                         two:suicide]];
    [timer play];
    score_ += 100;
    [scoreLabel_ setString:[NSString stringWithFormat:@"%d", score_]];
    [layer addChild:present];
  }];
  CCSequence* seq = [CCSequence actions:[CCAnimate actionWithAnimation:anim 
                                                  restoreOriginalFrame:YES], 
                     shoot, 
                     nil];
  [rochka_ runAction:seq];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
  if(!timer_.active) return NO;
  if (isYes_) {
    if (!isTouched_){
      [timer_ pause];
      isTouched_ = YES;
      [self onPresent];
    }
  } else {
    [self onGameOver];
  }
  return YES;
}

- (void)update:(ccTime)dt {
  KKInput* input = [KKInput sharedInput];
  CGSize screenSize = [CCDirector sharedDirector].screenSize;
  CGSize size = rochka_.contentSize;
  if (input.accelerometerAvailable && !onGameOver_) {
    KKAcceleration* ac = input.acceleration;
    double x = ac.y;
    double y = -ac.x;
    if (x < 0.1 && x > -0.1) x = 0;
    if (y < 0.1 && y > -0.1) y = 0;
    KWVector* v = [KWVector vectorWithPoint:CGPointMake(x * 3, y * 0)];
    v = [v max:3];
    rochka_.position = ccpAdd(rochka_.position, v.point);
    if (rochka_.position.x < 100 + size.width / 2) {
      rochka_.position = ccp(100 + size.width / 2, rochka_.position.y);
      if (v.x < -BACKGROUND_SPEED) {
        background_.velocity = [KWVector vectorWithPoint:CGPointMake(-v.x, 0)];
      } else {
        background_.velocity = [KWVector vectorWithPoint:CGPointMake(BACKGROUND_SPEED, 0)];
      }
    } else {
      background_.velocity = [KWVector vectorWithPoint:CGPointMake(BACKGROUND_SPEED, 0)];
    }
    if (rochka_.position.x > screenSize.width - size.width / 2) {
      rochka_.position = ccp(screenSize.width - size.width / 2, rochka_.position.y);
    }
  }
}

@end