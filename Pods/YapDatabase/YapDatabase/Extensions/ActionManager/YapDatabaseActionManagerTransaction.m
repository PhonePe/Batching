#import "YapDatabaseActionManagerTransaction.h"
#import "YapDatabaseActionManagerPrivate.h"
#import "YapDatabaseLogging.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/**
 * Define log level for this file: OFF, ERROR, WARN, INFO, VERBOSE
 * See YapDatabaseLogging.h for more information.
**/
#if DEBUG
  static const int ydbLogLevel = YDB_LOG_LEVEL_WARN;
#else
  static const int ydbLogLevel = YDB_LOG_LEVEL_WARN;
#endif
#pragma unused(ydbLogLevel)


@implementation YapDatabaseActionManagerTransaction

- (NSArray *)actionItemsForCollectionKey:(YapCollectionKey *)ck
{
	__unsafe_unretained YapDatabaseActionManagerConnection *parentConnection =
	  (YapDatabaseActionManagerConnection *)viewConnection;
	
	id cached = [parentConnection->actionItemsCache objectForKey:ck];
	if (cached)
	{
		if (cached == [NSNull null])
			return nil;
		else
			return cached;
	}
	
	id object = [databaseTransaction objectForKey:ck.key inCollection:ck.collection];
	
	NSArray<YapActionItem*> *actionItems = nil;
	if ([object conformsToProtocol:@protocol(YapActionable)])
	{
		actionItems = [[(id <YapActionable>)object yapActionItems] sortedArrayUsingSelector:@selector(compare:)];
	}
	
	if (actionItems)
		[parentConnection->actionItemsCache setObject:actionItems forKey:ck];
	else
		[parentConnection->actionItemsCache setObject:[NSNull null] forKey:ck];
	
	return actionItems;
}

- (NSArray *)actionItemsForKey:(NSString *)key inCollection:(NSString *)collection
{
	return [self actionItemsForCollectionKey:YapCollectionKeyCreate(collection, key)];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Transaction Hooks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * YapDatabase extension hook.
 * This method is invoked by a YapDatabaseReadWriteTransaction as a post-operation-hook.
**/
- (void)handleUpdateObject:(id)object
          forCollectionKey:(YapCollectionKey *)collectionKey
              withMetadata:(id)metadata
                     rowid:(int64_t)rowid
{
	YDBLogAutoTrace();
	
	__unsafe_unretained YapDatabaseActionManagerConnection *parentConnection =
	  (YapDatabaseActionManagerConnection *)viewConnection;
	
	[parentConnection->actionItemsCache removeObjectForKey:collectionKey];
	
	[super handleUpdateObject:object forCollectionKey:collectionKey withMetadata:metadata rowid:rowid];
}

/**
 * YapDatabase extension hook.
 * This method is invoked by a YapDatabaseReadWriteTransaction as a post-operation-hook.
**/
- (void)handleReplaceObject:(id)object forCollectionKey:(YapCollectionKey *)collectionKey withRowid:(int64_t)rowid
{
	YDBLogAutoTrace();
	
	__unsafe_unretained YapDatabaseActionManagerConnection *parentConnection =
	  (YapDatabaseActionManagerConnection *)viewConnection;
	
	[parentConnection->actionItemsCache removeObjectForKey:collectionKey];
	
	[super handleReplaceObject:object forCollectionKey:collectionKey withRowid:rowid];
}

/**
 * Subclasses MUST implement this method.
 * YapDatabaseReadWriteTransaction Hook, invoked post-op.
 *
 * Corresponds to the following method(s) in YapDatabaseReadWriteTransaction:
 * - touchObjectForKey:inCollection:collection:
**/
- (void)handleTouchObjectForCollectionKey:(YapCollectionKey *)collectionKey withRowid:(int64_t)rowid
{
	YDBLogAutoTrace();
	
	__unsafe_unretained YapDatabaseActionManagerConnection *parentConnection =
	  (YapDatabaseActionManagerConnection *)viewConnection;
	
	[parentConnection->actionItemsCache removeObjectForKey:collectionKey];
	
	[super handleTouchObjectForCollectionKey:collectionKey withRowid:rowid];
}

/**
 * Subclasses MUST implement this method.
 * YapDatabaseReadWriteTransaction Hook, invoked post-op.
 *
 * Corresponds to the following method(s) in YapDatabaseReadWriteTransaction:
 * - touchRowForKey:inCollection:
**/
- (void)handleTouchRowForCollectionKey:(YapCollectionKey *)collectionKey withRowid:(int64_t)rowid
{
	YDBLogAutoTrace();
	
	__unsafe_unretained YapDatabaseActionManagerConnection *parentConnection =
	  (YapDatabaseActionManagerConnection *)viewConnection;
	
	[parentConnection->actionItemsCache removeObjectForKey:collectionKey];
	
	[super handleTouchRowForCollectionKey:collectionKey withRowid:rowid];
}

/**
 * YapDatabase extension hook.
 * This method is invoked by a YapDatabaseReadWriteTransaction as a post-operation-hook.
**/
- (void)handleRemoveObjectForCollectionKey:(YapCollectionKey *)collectionKey withRowid:(int64_t)rowid
{
	YDBLogAutoTrace();
	
	__unsafe_unretained YapDatabaseActionManagerConnection *parentConnection =
	  (YapDatabaseActionManagerConnection *)viewConnection;
	
	[parentConnection->actionItemsCache removeObjectForKey:collectionKey];
	
	[super handleRemoveObjectForCollectionKey:collectionKey withRowid:rowid];
}

/**
 * YapDatabase extension hook.
 * This method is invoked by a YapDatabaseReadWriteTransaction as a post-operation-hook.
**/
- (void)handleRemoveObjectsForKeys:(NSArray *)keys inCollection:(NSString *)collection withRowids:(NSArray *)rowids
{
	YDBLogAutoTrace();
	
	__unsafe_unretained YapDatabaseActionManagerConnection *parentConnection =
	  (YapDatabaseActionManagerConnection *)viewConnection;
	
	for (NSString *key in keys)
	{
		[parentConnection->actionItemsCache removeObjectForKey:YapCollectionKeyCreate(collection, key)];
	}
	
	[super handleRemoveObjectsForKeys:keys inCollection:collection withRowids:rowids];
}

/**
 * YapDatabase extension hook.
 * This method is invoked by a YapDatabaseReadWriteTransaction as a post-operation-hook.
**/
- (void)handleRemoveAllObjectsInAllCollections
{
	YDBLogAutoTrace();
	
	__unsafe_unretained YapDatabaseActionManagerConnection *parentConnection =
	  (YapDatabaseActionManagerConnection *)viewConnection;
	
	[parentConnection->actionItemsCache removeAllObjects];
	
	[super handleRemoveAllObjectsInAllCollections];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Invalid
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setGrouping:(YapDatabaseViewGrouping __unused *)grouping
            sorting:(YapDatabaseViewSorting __unused *)sorting
         versionTag:(NSString __unused *)versionTag
{
	NSString *reason = @"This method is not available for YapDatabaseActionManager.";
	
	NSDictionary *userInfo = @{
	  NSLocalizedRecoverySuggestionErrorKey: @"YapDatabaseActionManager manages its own grouping & sorting."
	};
	
	@throw [NSException exceptionWithName:@"YapDatabaseException" reason:reason userInfo:userInfo];
}

@end
