//
//  IM_TestViewController.h
//  IM_Test
//
//  Created by Claudio Marforio on 7/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MagickWand.h"

@interface IM_TestViewController : UIViewController {
	IBOutlet UIImageView * imageView;
	
	MagickWand * magick_wand;
}

@property (nonatomic,retain) IBOutlet UIImageView * imageView;

- (IBAction)posterizeImage;

@end

