//
//  SMANArrayToStringValueTransformer.m
//  sman
//
//  Created by Roger Chen on 7/6/16.
//  Copyright © 2016 Roger Chen. All rights reserved.
//

#import "SMANArrayToStringValueTransformer.h"

@implementation SMANArrayToStringValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if (value == nil) {
        return nil;
    }

    if (![value respondsToSelector:@selector(componentsJoinedByString:)]) {
        [NSException raise:NSInternalInconsistencyException format:@"Value (%@) must be NSArray", value];
    }

    return [value componentsJoinedByString:@"\n"];
}

- (id)reverseTransformedValue:(id)value {
    if (value == nil) {
        return nil;
    }

    if (![value respondsToSelector:@selector(componentsSeparatedByString:)]) {
        [NSException raise:NSInternalInconsistencyException format:@"Value (%@) must be NSString", value];
    }

    NSArray *components = [value componentsSeparatedByString:@"\n"];
    NSMutableArray *filteredComponents = [NSMutableArray new];
    for (NSString *component in components) {
        NSString *trimmedComponent = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![trimmedComponent isEqualToString:@""]) {
            [filteredComponents addObject:trimmedComponent];
        }
    }
    return filteredComponents;
}

@end
