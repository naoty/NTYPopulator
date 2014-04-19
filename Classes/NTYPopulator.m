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
        NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:sqliteURL options:nil error:nil];
        
        self.managedObjectContext = [NSManagedObjectContext new];
        self.managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    }
    return self;
}

- (void)run
{
    NSArray *csvURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"csv" subdirectory:@"seeds"];
    for (NSURL *csvURL in csvURLs) {
        [self runWithSeedFileURL:csvURL];
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

#pragma mark - Private methods

- (NSURL *)applicationDocumentDirectoryURL
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
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
