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
    CGFloat defaultFontSize, labelsPadding;
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
    
    // ****** ------ <Data preperations> ------ ******
    defaultFontSize = 16;
    labelsPadding = 4;
    
    //Get values for y and x axis
    self.yAxisValues = [self.dataSource yAxisValuesForGraphView:self];
    self.xAxisValues = [self.dataSource xAxisValuesForGraphView:self];
    
    xAxisSeparatorInterval = 2; //Tells the view when to draw thicker grid line
    
    if ([self.dataSource respondsToSelector:@selector(xAxisSeparatorIntervalForGraphView:)]) {
        xAxisSeparatorInterval = [self.dataSource xAxisSeparatorIntervalForGraphView:self];
    }
    
    if ([self.dataSource respondsToSelector:@selector(shouldShowNumberLabelsInGraphView:)]) {
        shouldShowNumberLabels = [self.dataSource shouldShowNumberLabelsInGraphView:self];
    }

    if ([self.dataSource respondsToSelector:@selector(shouldDrawIdentifierAtTheOfLinesInGraphView:)]) {
        shouldDrawIdentifiersAtEndOfLines = [self.dataSource shouldDrawIdentifierAtTheOfLinesInGraphView:self];
    }
    
    //Increase insets according to text sizes. (Prevents text from getting cut)
    [self determineEdgeInsets];
    
    //canvasRect - The canvas of the graph to be drawn. Actual view is bigger than canvas and includes the edge insets.
    //Make the canvas rect considering our edge insets.
    canvasRect = CGRectMake(self.bounds.origin.x + self.edgeInsets.left,
                            self.bounds.origin.y + self.edgeInsets.top,
                            self.bounds.size.width - self.edgeInsets.right - self.edgeInsets.left,
                            self.bounds.size.height - self.edgeInsets.top - self.edgeInsets.bottom);

    //Calculate each step
    stepX = canvasRect.size.width / (self.xAxisValues.count - 1);
    stepY = canvasRect.size.height / (self.yAxisValues.count - 1);
    

    
    
    
    
    
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

    //Draw description label if text available.
    if (self.yAxisDescriptionText){
        [self drawYDescriptionLabelWithString:self.yAxisDescriptionText];
    }
    if (self.xAxisDescriptionText){
        [self drawXDescriptionLabelWithString:self.xAxisDescriptionText];
    }

    
    
    
    
    
    
    // ****** ------ <Graph lines drawing> ------ ******
    [self drawAllLineGraphsWithContext:context];
    CGContextStrokePath(context);
    
}
/******************************************************/
#pragma mark - Edge insets determination
/******************************************************/
-(void)determineEdgeInsets{
    
    // Axis description labels. For example, a graph of a growing kitten over time would show "months" for the X description label and "weight" for the Y description label.
    if (self.yAxisDescriptionText || self.xAxisDescriptionText) {
        
        CGFloat topPaddingToAdd = 0.0;
        CGFloat rightPaddingToAdd = 0.0;
        
        //Determine top edge inset to add considering our Y description label
        if(self.yAxisDescriptionText) {
            if (self.yAxisDescriptionTextAttributes){
                CGSize textSize = [self.yAxisDescriptionText sizeWithAttributes:self.yAxisDescriptionTextAttributes];
                topPaddingToAdd = labelsPadding + textSize.height;
            }else{
                CGSize textSize = [self.yAxisDescriptionText sizeWithAttributes:[self getDefaultFontAttributes]];
                topPaddingToAdd = labelsPadding + textSize.height;
            }
        }
        
        //Determine right edge inset to add considering our X description label
        if(self.xAxisDescriptionText){
            
            if (self.yAxisDescriptionTextAttributes){
                CGSize textSize = [self.xAxisDescriptionText sizeWithAttributes:self.yAxisDescriptionTextAttributes];
                rightPaddingToAdd = labelsPadding + textSize.width;
            }else{
                CGSize textSize = [self.xAxisDescriptionText sizeWithAttributes:[self getDefaultFontAttributes]];
                rightPaddingToAdd = labelsPadding + textSize.width;
            }
        }
        
        CGFloat topInsetToSet = self.edgeInsets.top + topPaddingToAdd;
        CGFloat rightInsetToSet = self.edgeInsets.right + rightPaddingToAdd;
        self.edgeInsets = UIEdgeInsetsMake(topInsetToSet, self.edgeInsets.left, self.edgeInsets.bottom, rightInsetToSet);
    }
    
    
    // X and Y axis value labels
    if (shouldShowNumberLabels){
        CGFloat bottomInset = labelsPadding + [self highestNumberStringHeight];
        CGFloat leftInset = labelsPadding + [self widestNumberStringWidth];
        self.edgeInsets = UIEdgeInsetsMake(self.edgeInsets.top, self.edgeInsets.left + leftInset, self.edgeInsets.bottom + bottomInset, self.edgeInsets.right);
    }
    
    if(shouldDrawIdentifiersAtEndOfLines){
        CGFloat rightInset = labelsPadding + [self widestIdentifierStringWidth];
        if (self.edgeInsets.right < rightInset){
            self.edgeInsets = UIEdgeInsetsMake(self.edgeInsets.top, self.edgeInsets.left, self.edgeInsets.bottom, rightInset);
        }
    }
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
                
                CGPoint labelPoint = CGPointMake(labelX, canvasRect.origin.y + canvasRect.size.height + labelsPadding );
                [h drawAtPoint:labelPoint withAttributes:attributes];
            }
        }else{
            NSString *h = [ NSString stringWithFormat:@"%@",self.xAxisValues[i]];
            NSMutableDictionary *attributes = [self getDefaultFontAttributes];

            
            CGSize labelSize = [h sizeWithAttributes:attributes];
            double labelX = (canvasRect.origin.x + (i * stepX)) - labelSize.width/2;
            
            CGPoint labelPoint = CGPointMake(labelX, canvasRect.origin.y + canvasRect.size.height + labelsPadding);
            [h drawAtPoint:labelPoint withAttributes:attributes];
        }
    }
}

-(void)drawBigXAxisNumbersLabels{ //Will be called only if xAxisSeperator value is bigger than 0
    for (int i = 0; i < self.xAxisValues.count; i++)
    {
        if (i % xAxisSeparatorInterval == 0 && i != 0) {
            
            //Add number label
            NSString *h = [NSString stringWithFormat:@"%@",self.xAxisValues[i]];
            NSMutableDictionary *attributes = [self getDefaultFontAttributes];

            CGPoint labelPoint = CGPointMake((canvasRect.origin.x + (i * stepX)-2), canvasRect.origin.y + canvasRect.size.height + labelsPadding);
            [h drawAtPoint:labelPoint withAttributes:attributes];
        }
    }
}

-(CGFloat)highestNumberStringHeight{ //For X axis labels
    CGFloat highest = 0.0;
    for (int i = 0; i < self.xAxisValues.count; i++)
    {
        NSString *h = [NSString stringWithFormat:@"%@",self.xAxisValues[i]];
        NSMutableDictionary *attributes = [self getDefaultFontAttributes];
        CGSize size = [h sizeWithAttributes:attributes];
        CGFloat height = size.height;
        if (height > highest){
            highest = height;
        }
    }
    return highest;
}

-(CGFloat)widestNumberStringWidth{ //For Y axis labels
    CGFloat widest = 0.0;
    for (int i = 0; i < self.yAxisValues.count; i++)
    {
        NSString *h = [NSString stringWithFormat:@"%@",self.yAxisValues[i]];
        NSMutableDictionary *attributes = [self getDefaultFontAttributes];
        CGSize size = [h sizeWithAttributes:attributes];
        CGFloat width = size.width;
        if (width > widest){
            widest = width;
        }
    }
    return widest;
}

-(CGFloat)widestIdentifierStringWidth{
    CGFloat widestIdentifierWidth = 0.0;

    if (shouldDrawIdentifiersAtEndOfLines) {
        NSInteger graphLinesCount = [self.dataSource numberOfGraphLinesInGraphView:self];
        
        for (int i = 0 ; i < graphLinesCount; i++) {
            NSDictionary *lineAttributes = [self.dataSource graphView:self graphLineAttributesForLineAtIndex:i];
            NSString *lineIdentifier = [lineAttributes objectForKey:kGraphLineAttributeIdentifier]; // Get line identifier. This will be the text at the end of the line
            NSMutableDictionary *attributes = [self getDefaultFontAttributes];
            CGSize identifierLabelSize = [lineIdentifier sizeWithAttributes:attributes];
            CGFloat width = identifierLabelSize.width;
            if (width > widestIdentifierWidth){
                widestIdentifierWidth = width;
            }
        }
        
    }
    return widestIdentifierWidth;
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
            [attributes setObject:[UIFont fontWithName:@"Avenir" size:defaultFontSize] forKey:NSFontAttributeName];
            [attributes setObject:[UIColor lightGrayColor] forKey:NSForegroundColorAttributeName];

            CGSize labelSize = [h sizeWithAttributes:attributes];
            CGPoint labelPoint = CGPointMake(canvasRect.origin.x - labelSize.width - labelsPadding, (canvasRect.origin.y + canvasRect.size.height) - (i * stepY) - labelSize.height/2);
            
            [h drawAtPoint:labelPoint withAttributes:attributes];
        }
        CGContextAddLineToPoint(context, canvasRect.origin.x + canvasRect.size.width, (canvasRect.origin.y + canvasRect.size.height) - (i * stepY));
        
    }
    
}

-(void)drawYDescriptionLabelWithString:(NSString*)string{
    NSMutableDictionary *attributes;
    if (self.yAxisDescriptionTextAttributes) {
        attributes = self.yAxisDescriptionTextAttributes;
    }else{
        //Default attributes
        attributes = [self getDefaultFontAttributes];
    }
    
    [string drawAtPoint:CGPointMake(canvasRect.origin.x, canvasRect.origin.y-[string sizeWithAttributes:attributes].height - labelsPadding) withAttributes:attributes];
}

-(void)drawXDescriptionLabelWithString:(NSString*)string{
    NSMutableDictionary *attributes;
    if (self.xAxisDescriptionTextAttributes) {
        attributes = self.xAxisDescriptionTextAttributes;
    }else{
        //Default attributes
        attributes = [self getDefaultFontAttributes];
    }
    [string drawAtPoint:CGPointMake(canvasRect.origin.x + canvasRect.size.width + labelsPadding, canvasRect.origin.y + canvasRect.size.height - [string sizeWithAttributes:attributes].height) withAttributes:attributes];
}

/******************************************************/
#pragma mark - Get font attributes
/******************************************************/
-(NSMutableDictionary*)getDefaultFontAttributes{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc]init];
    [attributes setObject:[UIFont systemFontOfSize:defaultFontSize] forKey:NSFontAttributeName];
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
                CGPoint labelPoint = CGPointMake(lastLinePoint.x + labelsPadding, lastLinePoint.y - labelSize.height);
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
    
    
    //    //If you want a straight line in case of two points only, you can use this:
//    if (points.count == 2) {
//        value = points[1];
//        CGPoint p2 = [value CGPointValue];
//        [path addLineToPoint:p2];
//        return path;
//    }
 
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



@end
