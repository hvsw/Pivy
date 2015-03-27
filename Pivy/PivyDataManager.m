//
//  PivyDataManager.m
//  Pivy
//
//  Created by Henrique Valcanaia on 3/26/15.
//  Copyright (c) 2015 Henrique Valcanaia. All rights reserved.
//

#import "PivyDataManager.h"
#import "Pivy.h"
#import <Parse/Parse.h>
#import "AppUtils.h"
#define DEBUG 1

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@implementation PivyDataManager

-(void)downloadPivys{
    if ([AppUtils hasInternetConnection]) {
        PFQuery *query = [Pivy query];
        [[[query fromLocalDatastore] orderByDescending:@"createdAt"] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (objects) {
#ifdef DEBUG
                NSLog(@"\n%ld pivys já baixados", objects.count);
#endif
                NSDate *date;
                if (objects.count > 0) {
                    Pivy *pivy = (Pivy*) objects[0];
                    date = pivy.createdAt;
#ifdef DEBUG
                    NSLog(@"Pivy 0: %@", pivy.createdAt);
#endif
                }else{
                    date = [[NSDate alloc] initWithTimeIntervalSince1970:0];
                }
                // Manda de volta pra main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"%@", date);
                });
                [self performSelectorOnMainThread:@selector(downloadAfterBackgroundWithDate:)
                                       withObject:date
                                    waitUntilDone:NO];
            }
        }];
    }
}

-(void)downloadAfterBackgroundWithDate: (NSDate *)date{
    PFQuery *query = [Pivy query];
#ifdef DEBUG
    NSLog(@"Maior data: %@", date);
#endif
    [query whereKey:@"createdAt" greaterThan:date];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (objects) {
#ifdef DEBUG
            NSLog(@"\n%ld pivys baixados AGORA", objects.count);
#endif
            NSMutableArray *pivys = [[NSMutableArray alloc] initWithArray:objects];
            [PFObject pinAllInBackground:pivys
                                   block:^(BOOL succeeded, NSError *error) {
                                       if (succeeded) {
                                           NSLog(@"Pivys pinados com sucesso!!!!!!");
                                       }else{
                                           NSLog(@"Sem sucesso");
                                       }
                                       if(error){
                                           NSLog(@"Erroooo: %@", error);
                                       }else{
                                           NSLog(@"Não deu erro");
                                       }
                                   }];
        }
    }];
}

-(void)clearLocalDB{
    NSInteger count;
    PFQuery *query = [Pivy query];
    [query fromLocalDatastore];
    for (Pivy *pivy in [query findObjects]) {
#ifndef NDEBUG
        if([pivy unpin]){
            count++;
        }
#else
        [pivy unpin];
#endif
    }
    
#ifndef NDEBUG
    NSLog(@"%ld pivys excluidos localmente", count);
#endif
    
}

@end
