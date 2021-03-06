#import "CommentServiceRemoteXMLRPC.h"
#import "RemoteComment.h"
#import <WordPressApi/WordPressApi.h>

static const NSInteger NumberOfCommentsToSync = 100;

@implementation CommentServiceRemoteXMLRPC

- (void)getCommentsForBlogID:(NSNumber *)blogID
                     success:(void (^)(NSArray *))success
                     failure:(void (^)(NSError *))failure
{
    [self getCommentsForBlogID:blogID options:nil success:success failure:failure];
}

- (void)getCommentsForBlogID:(NSNumber *)blogID
                     options:(NSDictionary *)options
                     success:(void (^)(NSArray *))success
                     failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *extraParameters = [NSMutableDictionary dictionaryWithDictionary:@{
                                      @"number": @(NumberOfCommentsToSync)
                                      }];
    if (options) {
        [extraParameters addEntriesFromDictionary:options];
    }
    NSArray *parameters = [self getXMLRPCArgsForBlogWithID:blogID extra:extraParameters];
    [self.api callMethod:@"wp.getComments"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([self remoteCommentsFromXMLRPCArray:responseObject]);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)getCommentWithID:(NSNumber *)commentID
               forBlogID:(NSNumber *)blogID
                 success:(void (^)(RemoteComment *comment))success
                 failure:(void (^)(NSError *))failure
{
    NSArray *parameters = [self getXMLRPCArgsForBlogWithID:blogID extra:commentID];
    [self.api callMethod:@"wp.getComment"
              parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (success) {
                      // TODO: validate response
                      RemoteComment *comment = [self remoteCommentFromXMLRPCDictionary:responseObject];
                      success(comment);
                  }
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  failure(error);
              }];
}

- (void)createComment:(RemoteComment *)comment
            forBlogID:(NSNumber *)blogID
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(comment.postID != nil);
    NSDictionary *commentDictionary = @{
                                        @"content": comment.content,
                                        @"comment_parent": comment.parentID,
                                        };
    NSArray *extraParameters = @[
                                 comment.postID,
                                 commentDictionary,
                                 ];
    NSArray *parameters = [self getXMLRPCArgsForBlogWithID:blogID extra:extraParameters];
    [self.api callMethod:@"wp.newComment"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSNumber *commentID = responseObject;
                     // TODO: validate response
                     [self getCommentWithID:commentID
                                  forBlogID:blogID
                                    success:success
                                    failure:failure];
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)updateComment:(RemoteComment *)comment
            forBlogID:(NSNumber *)blogID
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(comment.commentID != nil);
    NSNumber *commentID = comment.commentID;
    NSArray *extraParameters = @[
                                 comment.commentID,
                                 @{@"content": comment.content},
                                 ];
    NSArray *parameters = [self getXMLRPCArgsForBlogWithID:blogID extra:extraParameters];
    [self.api callMethod:@"wp.editComment"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     // TODO: validate response
                     [self getCommentWithID:commentID
                                  forBlogID:blogID
                                    success:success
                                    failure:failure];
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)moderateComment:(RemoteComment *)comment
              forBlogID:(NSNumber *)blogID
                success:(void (^)(RemoteComment *))success
                failure:(void (^)(NSError *))failure
{
    NSParameterAssert(comment.commentID != nil);
    NSArray *extraParameters = @[
                                 comment.commentID,
                                 @{@"status": comment.status},
                                 ];
    NSArray *parameters = [self getXMLRPCArgsForBlogWithID:blogID extra:extraParameters];
    [self.api callMethod:@"wp.editComment"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSNumber *commentID = responseObject;
                     // TODO: validate response
                     [self getCommentWithID:commentID
                                  forBlogID:blogID
                                    success:success
                                    failure:failure];
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)trashComment:(RemoteComment *)comment
           forBlogID:(NSNumber *)blogID
             success:(void (^)())success
             failure:(void (^)(NSError *))failure
{
    NSParameterAssert(comment.commentID != nil);
    NSArray *parameters = [self getXMLRPCArgsForBlogWithID:blogID extra:comment.commentID];
    [self.api callMethod:@"wp.deleteComment"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if (success) {
                         success();
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

#pragma mark - Private methods

- (NSArray *)remoteCommentsFromXMLRPCArray:(NSArray *)xmlrpcArray
{
    return [xmlrpcArray wp_map:^id(NSDictionary *xmlrpcComment) {
        return [self remoteCommentFromXMLRPCDictionary:xmlrpcComment];
    }];
}

- (RemoteComment *)remoteCommentFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary
{
    RemoteComment *comment = [RemoteComment new];
    comment.author = xmlrpcDictionary[@"author"];
    comment.authorEmail = xmlrpcDictionary[@"author_email"];
    comment.authorUrl = xmlrpcDictionary[@"author_url"];
    comment.commentID = [xmlrpcDictionary numberForKey:@"comment_id"];
    comment.content = xmlrpcDictionary[@"content"];
    comment.date = xmlrpcDictionary[@"date_created_gmt"];
    comment.link = xmlrpcDictionary[@"link"];
    comment.parentID = [xmlrpcDictionary numberForKey:@"parent"];
    comment.postID = [xmlrpcDictionary numberForKey:@"post_id"];
    comment.postTitle = xmlrpcDictionary[@"post_title"];
    comment.status = xmlrpcDictionary[@"status"];
    comment.type = xmlrpcDictionary[@"type"];
    return comment;
}

@end
