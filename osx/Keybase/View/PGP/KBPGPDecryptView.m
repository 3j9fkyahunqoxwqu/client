//
//  KBPGPDecryptView.m
//  Keybase
//
//  Created by Gabriel on 3/27/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import "KBPGPDecryptView.h"

#import "KBRPC.h"
#import "KBStream.h"
#import "KBPGPOutputView.h"
#import "KBPGPDecrypt.h"
#import "KBPGPDecryptFooterView.h"
#import "KBPGPDecrypted.h"
#import "KBPGPTextView.h"
#import "KBWork.h"

@interface KBPGPDecryptView ()
@property KBPGPTextView *textView;
@property KBPGPDecrypt *decrypter;
@end

@implementation KBPGPDecryptView

- (void)viewInit {
  [super viewInit];

  YOView *contentView = [YOView view];
  [self addSubview:contentView];
  _textView = [[KBPGPTextView alloc] init];
  [self addSubview:_textView];

  KBPGPDecryptFooterView *footerView = [[KBPGPDecryptFooterView alloc] init];
  footerView.decryptButton.targetBlock = ^{ [self decrypt]; };
  [self addSubview:footerView];

  self.viewLayout = [YOBorderLayout layoutWithCenter:_textView top:nil bottom:@[footerView] insets:UIEdgeInsetsZero spacing:0];
}

- (void)setASCIIData:(NSData *)data {
  [_textView setData:data];
}

- (void)decrypt {
  _decrypter = [[KBPGPDecrypt alloc] init];
  KBRPgpDecryptOptions *options = [[KBRPgpDecryptOptions alloc] init];

  NSData *data = [_textView.text dataUsingEncoding:NSASCIIStringEncoding];
  KBReader *reader = [KBReader readerWithData:data];
  KBWriter *writer = [KBWriter writer];
  KBStream *stream = [KBStream streamWithReader:reader writer:writer label:arc4random()];

  [KBActivity setProgressEnabled:YES sender:self];
  [_decrypter decryptWithOptions:options streams:@[stream] client:self.client sender:self completion:^(NSArray *works) {
    NSError *error = [works[0] error];
    [KBActivity setProgressEnabled:NO sender:self];
    if ([KBActivity setError:error sender:self]) return;
    KBWork *work = works[0];
    KBPGPDecrypted *decrypted = [work output];

    if (self.onDecrypt) {
      self.onDecrypt(self, decrypted);
    } else {
      [self _decrypted:decrypted];
    }
  }];
}

- (void)_decrypted:(KBPGPDecrypted *)decrypted {
  KBPGPOutputView *outputView = [[KBPGPOutputView alloc] init];
  NSString *text = [[NSString alloc] initWithData:decrypted.stream.writer.data encoding:NSUTF8StringEncoding];
  [outputView setText:text];
  [outputView setPgpSigVerification:decrypted.pgpSigVerification];
  [self.navigation pushView:outputView animated:YES];
  [self setNeedsLayout];
}

@end
