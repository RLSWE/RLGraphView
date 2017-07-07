//
//  RLGraphView.h
//  RLGraphViewExample
//
//  Created by Roni Leshes on 11/26/15.
//  Copyright © 2015 Roni Leshes. All rights reserved.


#import <UIKit/UIKit.h>



//Line attributes
extern NSString *const kGraphLineAttributeWidth;
extern NSString *const kGraphLineAttributeColor;
extern NSString *const kGraphLineAttributeIdentifier;


@class RLGraphView; // Pre class decleration for protocol

@protocol RLGraphViewDataSource <NSObject>

@required
// ****** ------ <Background Grid> ------ ******
-(NSArray*)yAxisValuesForGraphView:(RLGraphView*)graphView;
-(NSArray*)xAxisValuesForGraphView:(RLGraphView*)graphView;
@optional
-(BOOL)shouldShowNumberLabelsInGraphView:(RLGraphView*)graphView;
-(NSInteger)xAxisSeparatorIntervalForGraphView:(RLGraphView*)graphView;

//-(NSString*)yAxisDescriberTextInGraphView:(GraphView*)graphView;
//-(NSString*)xAxisDescriberTextInGraphView:(GraphView*)graphView;
//-(NSDictionary*)yAxisDescriberDictionaryInGraphView:(GraphView*)graphView;
//-(NSDictionary*)xAxisDescriberDictionaryInGraphView:(GraphView*)graphView;
// ****** ------ <Background Grid/> ------ ******







/**
 *  Tells view the data to show for each graph line
 *
 *  @param graphView The graph view that has those lines
 *  @param lineIndex The index of line that has this data
 *
 *  @return Values array for graph line
 */
-(NSArray*)graphView:(RLGraphView*)graphView dataArrayForGraphLineAtIndex:(NSInteger)lineIndex;

/**
 *  Tells view the amount of graph lines to draw
 *
 *  @param graphView The graph view that has those lines
 *z
 *  @return Number of graph lines to draw
 */
-(NSInteger)numberOfGraphLinesInGraphView:(RLGraphView*)graphView;

/**
 *  Tells graph view whether it should draw the graph line identifier at the end of the graph line or not
 *
 *  @param graphView The graph view that has the line
 *
 *  @return Boolean - Draw or not
 */
-(BOOL)shouldDrawIdentifierAtTheOfLinesInGraphView:(RLGraphView*)graphView; // Must put identifier in graphLineAttributes

/**
 *  Tells graph view the attributes for each line. Constants representing those attributes are in the top of current .h file.
 *
 *
 *  @param graphView The graph view that has those lines
 *  @param lineIndex Index of line with those attributes
 *
 *  @return Dictionary representing the attributes for the graph line
 */
-(NSDictionary*)graphView:(RLGraphView*)graphView graphLineAttributesForLineAtIndex:(NSInteger)lineIndex;

// ****** ------ <Graph Lines/> ------ ******





@end


@interface RLGraphView : UIView
@property (nonatomic)id<RLGraphViewDataSource> dataSource;
@property (nonatomic)UIEdgeInsets edgeInsets; // (Margins)
@property (nonatomic,strong)NSArray *yAxisValues;
@property (nonatomic,strong)NSArray *xAxisValues;

@property (nonatomic, strong)NSString *yAxisDescriberText;
@property (nonatomic, strong)NSString *xAxisDescriberText;
@property (nonatomic, strong)NSMutableDictionary *yAxisDescriberTextAttributes;
@property (nonatomic, strong)NSMutableDictionary *xAxisDescriberTextAttributes;

//@property (nonatomic) CGPoint lastCheckUpPoint;

/**
 *  Draws tracking checkups on graphview. Array objects SHOULD ONLY BE TrackingCheckups. 
 *
 *  @param trackingCheckups Array containing all the TrackingCheckups
 */
//-(void)drawTrackingCheckups:(NSArray*)trackingCheckups;








@end
