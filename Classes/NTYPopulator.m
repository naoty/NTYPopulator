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

@interface NTYPopulator ()
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSURL *applicationDocumentDirectoryURL;
@end

@implementation NTYPopulator

NSString * const kNTYPopulatorUserDefaultsKey = @"NTYPopulatorSeedFileModificationDates";

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
    
    [self deleteAllObjectsForEntityForName:entityName];
    
    NTYCSVTable *table = [[NTYCSVTable alloc] initWithContentsOfURL:seedFileURL];
    for (NSDictionary *row in table.rows) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
        for (NSString *header in table.headers) {
            [object setValue:row[header] forKey:header];
        }
    }
    [self.managedObjectContext save:nil];
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
    NSDictionary *defaults = @{kNTYPopulatorUserDefaultsKey: @{}};
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
    NSMutableDictionary *seedFileModificationDates = [[userDefaults dictionaryForKey:kNTYPopulatorUserDefaultsKey] mutableCopy];
    NSDate *modificationDate = seedFileModificationDates[seedFileURL.absoluteString];
    
    if (modificationDate == nil || ![modificationDate isEqualToDate:currentModificationDate]) {
        seedFileModificationDates[seedFileURL.absoluteString] = currentModificationDate;
        [userDefaults setObject:seedFileModificationDates forKey:kNTYPopulatorUserDefaultsKey];
        return YES;
    } else {
        return NO;
    }
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
