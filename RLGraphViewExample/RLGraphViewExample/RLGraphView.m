//
//  RLGraphView.m
//  GraphExample
//
//  Created by Roni Leshes on 11/26/15.
//  Copyright © 2015 Roni Leshes. All rights reserved.
//

#import "RLGraphView.h"






@interface RLGraphView ()
{
    CGRect canvasRect; //Graph rect. Actual view is bigger than canvas and includes the edge insets.
    float stepX,stepY; //Distance of each step.
    NSInteger xAxisSeparatorInterval; //Tells the view when to draw thicker grid line and number
    bool shouldShowNumberLabels, shouldDrawIdentifiersAtEndOfLines; //Data source bools
    CGFloat suggestedFontSize;
}

@end

NSString *const kGraphLineAttributeWidth = @"graphLineWidth";
NSString *const kGraphLineAttributeColor = @"graphLineColor";
NSString *const kGraphLineAttributeIdentifier = @"graphLineIdentifier"; // To show in the end of the graph line (goes a lil bit out of canvasRect to the right)

@implementation RLGraphView

/******************************************************/
#pragma mark - UIView
/******************************************************/
- (void)drawRect:(CGRect)rect {
    
    
    xAxisSeparatorInterval = 2;
    // ****** ------ <Data preperations> ------ ******
    if ([self.dataSource respondsToSelector:@selector(xAxisSeparatorIntervalForGraphView:)]) {
        xAxisSeparatorInterval = [self.dataSource xAxisSeparatorIntervalForGraphView:self];
    }
    
    if ([self.dataSource respondsToSelector:@selector(shouldShowNumberLabelsInGraphView:)]) {
        shouldShowNumberLabels = [self.dataSource shouldShowNumberLabelsInGraphView:self];
    }

    if ([self.dataSource respondsToSelector:@selector(shouldDrawIdentifierAtTheOfLinesInGraphView:)]) {
        shouldDrawIdentifiersAtEndOfLines = [self.dataSource shouldDrawIdentifierAtTheOfLinesInGraphView:self];
    }
    
    
    //Increase insets according to text size. (Prevents text from getting cut)
    if ((self.yAxisDescriberText || self.xAxisDescriberText)) {
        
        CGFloat topPaddingToAdd = 0.0;
        CGFloat rightPaddingToAdd = 0.0;
        
        if(self.yAxisDescriberText) {
            CGSize textSize = [self.yAxisDescriberText sizeWithAttributes:self.yAxisDescriberTextAttributes];
            topPaddingToAdd = textSize.height;
        }
        if(self.xAxisDescriberText){
            CGSize textSize = [self.xAxisDescriberText sizeWithAttributes:self.xAxisDescriberTextAttributes];
            rightPaddingToAdd = textSize.width;
        }
        CGFloat topInsetToSet = self.edgeInsets.top + topPaddingToAdd;
        CGFloat rightInsetToSet = self.edgeInsets.right + rightPaddingToAdd;
        self.edgeInsets = UIEdgeInsetsMake(topInsetToSet, self.edgeInsets.left, self.edgeInsets.bottom, rightInsetToSet);
    }
    
    
    //Make the canvas rect according to edge insets
    canvasRect = CGRectMake(self.bounds.origin.x + self.edgeInsets.left,
                            self.bounds.origin.y + self.edgeInsets.top,
                            self.bounds.size.width - self.edgeInsets.right - self.edgeInsets.left,
                            self.bounds.size.height - self.edgeInsets.top - self.edgeInsets.bottom);
    
    //Set suggested font size
    suggestedFontSize = canvasRect.size.height / 20;
    
    
    //Get values for y and x axis
    self.yAxisValues = [self.dataSource yAxisValuesForGraphView:self];
    self.xAxisValues = [self.dataSource xAxisValuesForGraphView:self];
    
    //Calculate each step
    stepX = canvasRect.size.width / (self.xAxisValues.count - 1);
    stepY = canvasRect.size.height / (self.yAxisValues.count - 1);
    
    // ****** ------ <Data preperations/> ------ ******

    
    
    
    
    
    
    
    
    
    
    // ****** ------ <Background grid drawing> ------ ******

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 0.6);
    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
    
    [self drawThinVerticalLinesWithContext:context];
    [self drawHorizontalLinesWithContext:context];
    if (shouldShowNumberLabels) {
        [self drawSmallXAxisNumbersLabels];
    }
    CGContextStrokePath(context);
    
    
    if (xAxisSeparatorInterval>0) {
        [self drawThickVerticalLinesWithContext:context];
        CGContextStrokePath(context);
        
        if (shouldShowNumberLabels) {
            [self drawBigXAxisNumbersLabels];
            CGContextStrokePath(context);
        }
    }
    
    //Draw describer if text available.
    if (self.yAxisDescriberText){
        [self drawYDescriberLabelWithString:self.yAxisDescriberText];
    }
    if (self.xAxisDescriberText){
        [self drawXDescriberLabelWithString:self.xAxisDescriberText];
    }
    // ****** ------ <Background grid drawing/> ------ ******

    
    
    
    
    
    
    
    // ****** ------ <Graph lines drawing> ------ ******
    [self drawAllLineGraphsWithContext:context];
    CGContextStrokePath(context);
    // ****** ------ <Graph lines drawing/> ------ ******
    
    
    
    
    
    //Test
//    CGContextSetStrokeColorWithColor(context, [[UIColor orangeColor] CGColor]);

}

/******************************************************/
#pragma mark - Background grid drawing
/******************************************************/

-(void)drawThinVerticalLinesWithContext:(CGContextRef)context{
    for (int i = 0; i < self.xAxisValues.count; i++)
    {
        if (i % xAxisSeparatorInterval != 0) {
            CGContextMoveToPoint(context, canvasRect.origin.x + (i * stepX), canvasRect.origin.y);
            CGContextAddLineToPoint(context, canvasRect.origin.x + (i * stepX) , canvasRect.origin.y + canvasRect.size.height);
        }

    }
}
-(void)drawThickVerticalLinesWithContext:(CGContextRef)context{
    CGContextSetLineWidth(context, 1.5);
    for (int i = 0; i < self.xAxisValues.count; i++)
    {
        if (i % xAxisSeparatorInterval == 0) {
            CGContextMoveToPoint(context, canvasRect.origin.x + (i * stepX), canvasRect.origin.y);
            CGContextAddLineToPoint(context, canvasRect.origin.x + (i * stepX), canvasRect.origin.y + canvasRect.size.height);
        }
    }
}

-(void)drawSmallXAxisNumbersLabels{
    for (int i = 0; i < self.xAxisValues.count; i++)
    {
        if (xAxisSeparatorInterval>0) {
            if (i % xAxisSeparatorInterval != 0 || i == 0) {
                NSString *h = [ NSString stringWithFormat:@"%@",self.xAxisValues[i]];
                NSMutableDictionary *attributes = [self getDefaultFontAttributes];

                
                CGSize labelSize = [h sizeWithAttributes:attributes];
                double labelX = (canvasRect.origin.x + (i * stepX)) - labelSize.width/2;
                
                CGPoint labelPoint = CGPointMake(labelX, canvasRect.origin.y + canvasRect.size.height);
                [h drawAtPoint:labelPoint withAttributes:attributes];
            }
        }else{
            NSString *h = [ NSString stringWithFormat:@"%@",self.xAxisValues[i]];
            NSMutableDictionary *attributes = [self getDefaultFontAttributes];

            
            CGSize labelSize = [h sizeWithAttributes:attributes];
            double labelX = (canvasRect.origin.x + (i * stepX)) - labelSize.width/2;
            
            CGPoint labelPoint = CGPointMake(labelX, canvasRect.origin.y + canvasRect.size.height);
            [h drawAtPoint:labelPoint withAttributes:attributes];
        }
    }
}

-(void)drawBigXAxisNumbersLabels{ //Will be called only if xAxisSeperator value is bigger than 0
    for (int i = 0; i < self.xAxisValues.count; i++)
    {
        if (i % xAxisSeparatorInterval == 0 && i != 0) {
            
            //Add number label
            NSString *h = [ NSString stringWithFormat:@"%@",self.xAxisValues[i]];
            NSMutableDictionary *attributes = [self getDefaultFontAttributes];

            CGPoint labelPoint = CGPointMake((canvasRect.origin.x + (i * stepX)-2), canvasRect.origin.y + canvasRect.size.height + 4);
            [h drawAtPoint:labelPoint withAttributes:attributes];
        }
    }
}


-(void)drawHorizontalLinesWithContext:(CGContextRef)context{
    
    
    //First line
    CGContextMoveToPoint(context, canvasRect.origin.x, (canvasRect.origin.y + canvasRect.size.height));
    CGContextAddLineToPoint(context, canvasRect.origin.x + canvasRect.size.width,  (canvasRect.origin.y + canvasRect.size.height));

    //Rest
    for (int i = 1; i < self.yAxisValues.count; i++)
    {
        CGContextMoveToPoint(context, canvasRect.origin.x, (canvasRect.origin.y + canvasRect.size.height) - (i * stepY));
        
        
        //Number labels
        if (shouldShowNumberLabels) {
            NSString *h = [ NSString stringWithFormat:@"%@",self.yAxisValues[i]];
            
            NSMutableDictionary *attributes = [[NSMutableDictionary alloc]init];
            [attributes setObject:[UIFont fontWithName:@"Avenir" size:suggestedFontSize] forKey:NSFontAttributeName];
            [attributes setObject:[UIColor lightGrayColor] forKey:NSForegroundColorAttributeName];
//            NSMutableDictionary *attributes = [self getDefaultFontAttributes];

            
//            NSDictionary *attributes = @{NSFontAttributeName : [UIFont systemFontOfSize:6.0]};
            CGSize labelSize = [h sizeWithAttributes:attributes];
            CGPoint labelPoint = CGPointMake(canvasRect.origin.x - labelSize.width - 2, (canvasRect.origin.y + canvasRect.size.height) - (i * stepY) - labelSize.height/2);
            
            [h drawAtPoint:labelPoint withAttributes:attributes];
        }
        
        CGContextAddLineToPoint(context, canvasRect.origin.x + canvasRect.size.width, (canvasRect.origin.y + canvasRect.size.height) - (i * stepY));
        
    }
    
}

-(void)drawYDescriberLabelWithString:(NSString*)string{
    NSMutableDictionary *attributes;
    if (self.yAxisDescriberTextAttributes) {
        attributes = self.yAxisDescriberTextAttributes;
    }else{
        //Default attributes
        attributes = [self getDefaultFontAttributes];
    }
    
    [string drawAtPoint:CGPointMake(canvasRect.origin.x + 4, canvasRect.origin.y-[string sizeWithAttributes:attributes].height-4) withAttributes:attributes];
}

-(void)drawXDescriberLabelWithString:(NSString*)string{
    NSMutableDictionary *attributes;
    if (self.xAxisDescriberTextAttributes) {
        attributes = self.xAxisDescriberTextAttributes;
    }else{
        //Default attributes
        attributes = [self getDefaultFontAttributes];
    }
    [string drawAtPoint:CGPointMake(canvasRect.origin.x + canvasRect.size.width+4, canvasRect.origin.y + canvasRect.size.height -[string sizeWithAttributes:attributes].height) withAttributes:attributes];
}

/******************************************************/
#pragma mark - Get font attributes
/******************************************************/
-(NSMutableDictionary*)getDefaultFontAttributes{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc]init];
    [attributes setObject:[UIFont systemFontOfSize:suggestedFontSize] forKey:NSFontAttributeName];
    [attributes setObject:[UIColor blackColor] forKey:NSForegroundColorAttributeName];
    return attributes;
}


/******************************************************/
#pragma mark - Graph Lines drawing
/******************************************************/



- (void)drawAllLineGraphsWithContext:(CGContextRef)ctx
{
    if ([self.dataSource respondsToSelector:@selector(numberOfGraphLinesInGraphView:)] && [self.dataSource respondsToSelector:@selector(graphView:dataArrayForGraphLineAtIndex:)]) {
        
        NSInteger graphLinesCount = [self.dataSource numberOfGraphLinesInGraphView:self];
        
        for (int i = 0 ; i < graphLinesCount; i++) {
            
            //Get line data
            NSArray *currentLineDataArray = [self.dataSource graphView:self dataArrayForGraphLineAtIndex:i];
            
            
            
            //Set line attributes
            NSDictionary *lineAttributes;
            CGFloat lineWidth = 0.5f;
            CGColorRef lineColor = [UIColor blackColor].CGColor;
            if([self.dataSource respondsToSelector:@selector(graphView:graphLineAttributesForLineAtIndex:)]){
                
                lineAttributes = [self.dataSource graphView:self graphLineAttributesForLineAtIndex:i];
                lineWidth = [[lineAttributes objectForKey:kGraphLineAttributeWidth] floatValue];
                UIColor *color = [lineAttributes objectForKey:kGraphLineAttributeColor];
                lineColor = color.CGColor;
                
            }
            
            CGContextSetStrokeColorWithColor(ctx, lineColor);

            CGContextBeginPath(ctx);
            CGContextMoveToPoint(ctx, canvasRect.origin.x,(canvasRect.origin.y + canvasRect.size.height));
            
            
            float yValuesRange = [self.yAxisValues.lastObject floatValue] - [self.yAxisValues.firstObject floatValue];
            float yStartValue = [self.yAxisValues.firstObject floatValue];
            
            NSMutableArray *points = [[NSMutableArray alloc]init];
            CGPoint p;
            
            for (int i = 0; i < self.xAxisValues.count; i++)
            {
                                                                        //First value on y    ----  //Max y
                if (i < currentLineDataArray.count) {
                    float pointFloatValue = ([currentLineDataArray[i] floatValue]-yStartValue) / yValuesRange;
                    
                    p = CGPointMake(canvasRect.origin.x  + (i * stepX), (canvasRect.origin.y + canvasRect.size.height) - (canvasRect.size.height * pointFloatValue));
                    [points addObject:[NSValue valueWithCGPoint:p]];
                }
            }
            if (shouldDrawIdentifiersAtEndOfLines) {
                //Draw extra straight horizontal line at the end of the graph line.
                CGPoint endPoint = CGPointMake(p.x+16, p.y);
                [points addObject:[NSValue valueWithCGPoint:endPoint]];

            }
            UIBezierPath *linePath = [RLGraphView curvedPathWithPoints:points];
            
            [linePath setLineWidth:lineWidth];
            [linePath stroke];
            
            if (shouldDrawIdentifiersAtEndOfLines) {
                //Draw string at the end of the line
                NSString *lineIdentifier = [lineAttributes objectForKey:kGraphLineAttributeIdentifier] ;
                UIColor *textColor = [UIColor colorWithCGColor:lineColor];

                NSMutableDictionary *attributes = [self getDefaultFontAttributes];

                [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
                
                CGSize labelSize = [lineIdentifier sizeWithAttributes:attributes];
                NSValue *value = [points objectAtIndex:points.count-2];
                CGPoint lastLinePoint = [value CGPointValue];
                CGPoint labelPoint = CGPointMake(lastLinePoint.x+4, lastLinePoint.y - labelSize.height);
                [lineIdentifier drawAtPoint:labelPoint withAttributes:attributes];
            }
        }
    }

}

+(UIBezierPath *)curvedPathWithPoints:(NSArray *)points
{
    UIBezierPath *path = [UIBezierPath bezierPath];

    
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];
    
    
//    //Use to make straight line if only 2 points
//    if (points.count == 2) {
//        value = points[1];
//        CGPoint p2 = [value CGPointValue];
//        [path addLineToPoint:p2];
//        return path;
//    }
//    
    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        
        CGPoint midPoint = midPointForPoints(p1, p2);
        [path addCurveToPoint:p2 controlPoint1:p1 controlPoint2:midPoint];

        p1 = p2;
    }

    return path;
    
}

/**
 *  Get mid point between two points
 *
 *  @param p1 First point
 *  @param p2 Second point
 *
 *  @return middle point for the two points given
 */
static CGPoint midPointForPoints(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
}

//unused - Used to make control point for quad curved lines
//static CGPoint controlPointForPoints(CGPoint p1, CGPoint p2) {
//    CGPoint controlPoint = midPointForPoints(p1, p2);
//    CGFloat diffY = abs(p2.y - controlPoint.y);
//
//    if (p1.y < p2.y)
//        controlPoint.y += diffY;
//    else if (p1.y > p2.y)
//        controlPoint.y -= diffY;
//
//    return controlPoint;
//}

//unused - Generate random float - Used for tests
//float randomFloat(float Min, float Max){
//    return ((arc4random()%RAND_MAX)/(RAND_MAX*1.0))*(Max-Min)+Min;
//}















@end
