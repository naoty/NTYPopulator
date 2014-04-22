//
//  NTYPopulator.m
//  Pods
//
//  Created by naoty on 2014/04/20.
//
//

#import <CoreData/CoreData.h>
#import "NTYPopulator.h"
#import "NTYCSVTable.h"
#import "NSArray+NTYDifference.h"

@interface NTYPopulator ()
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSURL *applicationDocumentDirectoryURL;
@end

@implementation NTYPopulator

NSString * const kNTYPopulatorSeedFileModificationDatesKey = @"NTYPopulatorSeedFileModificationDates";
NSString * const kNTYPopulatorSeedIDsKey = @"NTYPopulatorSeedIDs";

- (instancetype)init
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *applicationName = [[bundle infoDictionary] valueForKey:@"CFBundleName"];
    NSURL *modelURL = [bundle URLForResource:@"Model" withExtension:@"momd"];
    NSURL *sqliteURL = [self.applicationDocumentDirectoryURL URLByAppendingPathComponent:[applicationName stringByAppendingPathExtension:@"sqlite"]];
    
    return [self initWithModelURL:modelURL sqliteURL:sqliteURL];
}

- (instancetype)initWithModelURL:(NSURL *)modelURL sqliteURL:(NSURL *)sqliteURL
{
    self = [super init];
    if (self) {
        [self setUpManagedObjectContextWithModelURL:modelURL sqliteURL:sqliteURL];
        [self setUpUserDefaults];
    }
    return self;
}

- (void)run
{
    NSArray *csvURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"csv" subdirectory:@"seeds"];
    for (NSURL *csvURL in csvURLs) {
        if ([self checkUpdateOnSeedFileOfURL:csvURL]) {
            [self runWithSeedFileURL:csvURL];
        }
    }
}

- (void)runWithSeedFileURL:(NSURL *)seedFileURL
{
    NSString *entityName = [[[seedFileURL lastPathComponent] stringByDeletingPathExtension] capitalizedString];
    NTYCSVTable *table = [[NTYCSVTable alloc] initWithContentsOfURL:seedFileURL];
    
    if ([table.headers containsObject:@"seed_id"]) {
        [self safelyRunWithEntityName:entityName CSVTable:table];
    } else {
        [self unsafelyRunWithEntityName:entityName CSVTable:table];
    }
}

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Private methods

- (NSURL *)applicationDocumentDirectoryURL
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)setUpManagedObjectContextWithModelURL:(NSURL *)modelURL sqliteURL:(NSURL *)sqliteURL
{
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:sqliteURL options:nil error:nil];
    
    self.managedObjectContext = [NSManagedObjectContext new];
    self.managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
}

- (void)setUpUserDefaults
{
    NSDictionary *defaults = @{
        kNTYPopulatorSeedFileModificationDatesKey: @{},
        kNTYPopulatorSeedIDsKey: @[]
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (BOOL)checkUpdateOnSeedFileOfURL:(NSURL *)seedFileURL
{
    NSDate *currentModificationDate;
    NSError *error;
    [seedFileURL getResourceValue:&currentModificationDate forKey:NSURLContentModificationDateKey error:&error];
    
    if (currentModificationDate == nil || error) {
        return YES;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *seedFileModificationDates = [[userDefaults dictionaryForKey:kNTYPopulatorSeedFileModificationDatesKey] mutableCopy];
    NSDate *modificationDate = seedFileModificationDates[seedFileURL.absoluteString];
    
    if (modificationDate == nil || ![modificationDate isEqualToDate:currentModificationDate]) {
        seedFileModificationDates[seedFileURL.absoluteString] = currentModificationDate;
        [userDefaults setObject:seedFileModificationDates forKey:kNTYPopulatorSeedFileModificationDatesKey];
        return YES;
    } else {
        return NO;
    }
}

- (void)safelyRunWithEntityName:(NSString *)entityName CSVTable:(NTYCSVTable *)table
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *newSeedIDs = table.columns[@"seed_id"];
    NSArray *oldSeedIDs = [userDefaults arrayForKey:kNTYPopulatorSeedIDsKey];
    
    NSArray *seedIDsToInsert = [newSeedIDs minusArray:oldSeedIDs];
    for (NSNumber *seedID in seedIDsToInsert) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
        NSDictionary *row = [[table rowsOfValue:seedID forHeader:@"seed_id"] firstObject];
        for (NSString *header in table.headers) {
            [object setValue:row[header] forKeyPath:header];
        }
    }
    
    NSArray *seedIDsToDelete = [oldSeedIDs minusArray:newSeedIDs];
    for (NSNumber *seedID in seedIDsToDelete) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
        request.predicate = [NSPredicate predicateWithFormat:@"seed_id = %@", seedID];
        NSManagedObject *object = [[self.managedObjectContext executeFetchRequest:request error:nil] firstObject];
        [self.managedObjectContext deleteObject:object];
    }
    
    NSArray *seedIDsToUpdate = [newSeedIDs intersectArray:oldSeedIDs];
    for (NSNumber *seedID in seedIDsToUpdate) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
        request.predicate = [NSPredicate predicateWithFormat:@"seed_id = %@", seedID];
        NSManagedObject *object = [[self.managedObjectContext executeFetchRequest:request error:nil] firstObject];
        NSDictionary *row = [[table rowsOfValue:seedID forHeader:@"seed_id"] firstObject];
        for (NSString *header in table.headers) {
            [object setValue:row[header] forKeyPath:header];
        }
    }
    
    [self.managedObjectContext save:nil];
    
    [userDefaults setObject:newSeedIDs forKey:kNTYPopulatorSeedIDsKey];
}

- (void)unsafelyRunWithEntityName:(NSString *)entityName CSVTable:(NTYCSVTable *)table
{
    [self deleteAllObjectsForEntityForName:entityName];
    
    for (NSDictionary *row in table.rows) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
        for (NSString *header in table.headers) {
            [object setValue:row[header] forKey:header];
        }
    }
    
    [self.managedObjectContext save:nil];
}

- (void)deleteAllObjectsForEntityForName:(NSString *)entityName
{
    NSFetchRequest *request = [NSFetchRequest new];
    request.entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:nil];
    for (NSManagedObject *object in objects) {
        [self.managedObjectContext deleteObject:object];
    }
    [self.managedObjectContext save:nil];
}

@end
