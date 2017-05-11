//
//  BSLeDiscoveryTests.m
//  BLEListerTests
//
//  Created by Steve Baker on 9/26/13.
//  Copyright (c) 2013 Beepscore LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
//#import "SHTestCaseAdditions.h"
#import "BSLeDiscovery.h"
#import "BSLeDiscovery_Private.h"
#import "BSBlePeripheral.h"
#import "BSJSONParser.h"
#import "OCMock/OCMock.h"
#import "BSBleConstants.h"
#import "BSStubCBCentralManager.h"

@interface BSLeDiscoveryTests : XCTestCase
@property (strong, nonatomic) BSLeDiscovery *bsLeDiscovery;
@end

@implementation BSLeDiscoveryTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - test sharedInstance
- (void)testSharedInstance {
    self.bsLeDiscovery = [BSLeDiscovery sharedInstance];
    // call sharedInstance again to check it returns the same instance
    // XCTAssertEqual is the identical object
    // XCTAssertEqualObjects tests objectA isEqual:objectB
    XCTAssertEqual([BSLeDiscovery sharedInstance],
                   self.bsLeDiscovery,
                   @"expected sharedInstance returns same instance");
}

- (void)testSharedInstanceCentralManager {
    self.bsLeDiscovery = [BSLeDiscovery sharedInstance];
    // Could reduce scope of this test by testing sharedInstance calls
    // designated initializer.
    XCTAssertNotNil(self.bsLeDiscovery.centralManager,
                   @"expected sharedInstance sets centralManager");
}

- (void)testSharedInstanceCentralManagerDelegate {
    self.bsLeDiscovery = [BSLeDiscovery sharedInstance];
    // Could reduce scope of this test by testing sharedInstance calls
    // designated initializer.
    XCTAssertEqualObjects(self.bsLeDiscovery,
                          self.bsLeDiscovery.centralManager.delegate,
                   @"expected sharedInstance sets centralManager delegate to self");
}

- (void)testSharedInstanceConnectedServices {
    self.bsLeDiscovery = [BSLeDiscovery sharedInstance];
    // Could reduce scope of this test by testing sharedInstance calls
    // designated initializer.
    XCTAssertNotNil(self.bsLeDiscovery.connectedServices,
                    @"expected sharedInstance sets connectedServices");
    XCTAssertEqualObjects([NSMutableArray arrayWithArray:@[]],
                          self.bsLeDiscovery.connectedServices,
                          @"expected sharedInstance connectedServices is empty array");
}

- (void)testSharedInstanceNotificationCenter {
    self.bsLeDiscovery = [BSLeDiscovery sharedInstance];
    // Could reduce scope of this test by testing sharedInstance calls
    // designated initializer.
    XCTAssertNotNil(self.bsLeDiscovery.notificationCenter,
                    @"expected sharedInstance sets notificationCenter");
    XCTAssertEqualObjects([NSNotificationCenter defaultCenter],
                          self.bsLeDiscovery.notificationCenter,
                          @"expected sharedInstance uses default notificationCenter");
}

# pragma mark - test designated initializer
- (void)testDesignatedInitializerSetsProperties {
    CBCentralManager *fakeCentralManager = [[CBCentralManager alloc] init];
    NSMutableArray *fakeFoundPeripherals = [NSMutableArray arrayWithArray:@[@"wolf", @"dog", @"dingo"]];
    NSMutableArray *fakeConnectedServices = [NSMutableArray arrayWithArray:@[@"lion", @"cat", @"lynx"]];
    NSNotificationCenter *fakeNotificationCenter = [[NSNotificationCenter alloc] init];

    self.bsLeDiscovery = [[BSLeDiscovery alloc]
                          initWithCentralManager:fakeCentralManager
                          foundPeripherals:fakeFoundPeripherals
                          connectedServices:fakeConnectedServices
                          notificationCenter:fakeNotificationCenter];

    XCTAssertEqualObjects(fakeCentralManager, self.bsLeDiscovery.centralManager, @"");
    XCTAssertEqualObjects(fakeFoundPeripherals, self.bsLeDiscovery.foundPeripherals, @"");
    XCTAssertEqualObjects(fakeConnectedServices, self.bsLeDiscovery.connectedServices, @"");
    XCTAssertEqualObjects(fakeNotificationCenter, self.bsLeDiscovery.notificationCenter, @"");
}

- (void)testDesignatedInitializerWithParamsNil {
    self.bsLeDiscovery = [[BSLeDiscovery alloc]
                          initWithCentralManager:nil
                          foundPeripherals:nil
                          connectedServices:nil
                          notificationCenter:nil];

    XCTAssertNil(self.bsLeDiscovery.centralManager, @"expected centralManager nil");
    XCTAssertNil(self.bsLeDiscovery.foundPeripherals, @"expected foundPeripherals nil");
    XCTAssertNil(self.bsLeDiscovery.connectedServices, @"expected connectedServices nil");
    XCTAssertNil(self.bsLeDiscovery.notificationCenter, @"expected notificationCenter nil");
}

# pragma mark - test asynchronous
// TODO: replace deleted third party SHTestCaseAdditions with Apple XCTestExpectation
/*
- (void)testSH_waitForTimeInterval {
    __block BOOL assertion = NO;

    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        assertion = YES;
    });

    [self SH_waitForTimeInterval:delayInSeconds];
    XCTAssertTrue(assertion, @"expected assertion true");
}
*/

// TODO: testFoundPeripheralsAsync fails. Fix it.
// This test assumes iOS device will find at least one peripheral
// and the first is a Red Bear Lab Ble Shield
/*
- (void)testFoundPeripheralsAsync {

    // using __block allows block to change bsLeDiscovery
    // must set foundPeripherals to empty mutable array so we can add objects to it.
    __block BSLeDiscovery *bsLeDiscovery = [[BSLeDiscovery alloc]
                                    initWithCentralManager:nil
                                    foundPeripherals:[NSMutableArray arrayWithArray:@[]]
                                    connectedServices:nil
                                    notificationCenter:nil];

    // Init with queue non-nil.
    // http://stackoverflow.com/questions/18970247/cbcentralmanager-changes-for-ios-7
    dispatch_queue_t centralQueue = dispatch_queue_create("com.beepscore.central_manager", DISPATCH_QUEUE_SERIAL);
    // CBCentralManager should instantiate and then power on.
    CBCentralManager *centralManager = [[CBCentralManager alloc]
                                        initWithDelegate:bsLeDiscovery
                                        queue:centralQueue];

    bsLeDiscovery.centralManager = centralManager;

    __block BOOL didStartScanning = NO;

    NSDictionary *bleDevices = [BSJSONParser dictFromJSONFile:@"bleDevices"];
    NSString *expectedIdentifierString = bleDevices[@"redbearshield"][@"identifier"];
    NSString *expectedName = bleDevices[@"redbearshield"][@"name"];

    SHTestCaseBlock testBlock = ^(BOOL *didFinish) {

        NSLog(@"In testBlock. foundPeripherals: %@", bsLeDiscovery.foundPeripherals);

        if(CBManagerStatePoweredOn != bsLeDiscovery.centralManager.state) {
            NSLog(@"still not powered on");
        } else {
            NSLog(@"CBManagerStatePoweredOn");
            // centralManager is powered on, ok to scan and retrieve
            // http://stackoverflow.com/questions/17118534/when-would-cbcentralmanagers-state-ever-be-powered-on-but-still-give-me-a-not?rq=1
            
            if(!didStartScanning) {
                // http://stackoverflow.com/questions/10178293/how-to-get-list-of-available-bluetooth-devices?rq=1
                //[bsLeDiscovery startScanningForUUIDString:expectedIdentifierString];
                //[bsLeDiscovery startScanningForUUIDString:@"180A"];
                [bsLeDiscovery startScanningForUUIDString:nil];
                didStartScanning = YES;
            }
            
            if ( 1 <= [bsLeDiscovery.foundPeripherals count]) {
                CBPeripheral *peripheral = [bsLeDiscovery.foundPeripherals firstObject];

                NSLog(@"my peripheral %@", peripheral);
                XCTAssertEqualObjects(expectedIdentifierString,
                                      [peripheral.identifier UUIDString],
                                      @"expected first found peripheral UUIDString");
                XCTAssertEqualObjects(expectedName,
                                      peripheral.name,
                                      @"expected first found peripheral name");
                
                // dereference the pointer to set the BOOL value
                *didFinish = YES;
            }
        }
    };

    // SH_performAsyncTestsWithinBlock calls testBlock
    // and supplies its argument, a pointer to BOOL didFinish.
    // SH_performAsyncTestsWithinBlock keeps calling the block
    // until the block sets didFinish YES or the test times out.
    [self SH_performAsyncTestsWithinBlock:testBlock withTimeout:10.0];
}
 */

// This test is not asynchronous.
- (void)testFoundPeripherals {

    // must set foundPeripherals to empty mutable array so we can add objects to it.
    BSLeDiscovery *bsLeDiscovery = [[BSLeDiscovery alloc]
                                    initWithCentralManager:nil
                                    foundPeripherals:@[]
                                    connectedServices:nil
                                    notificationCenter:nil];

    // Init with queue nil (uses default main queue), test failed.
    // CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
    // Init with queue non-nil.
    // http://stackoverflow.com/questions/18970247/cbcentralmanager-changes-for-ios-7
    dispatch_queue_t centralQueue = dispatch_queue_create("com.beepscore.central_manager", DISPATCH_QUEUE_SERIAL);
    // CBCentralManager should instantiate and then power on.
    CBCentralManager *centralManager = [[CBCentralManager alloc]
                                        initWithDelegate:bsLeDiscovery
                                        queue:centralQueue];

    bsLeDiscovery.centralManager = centralManager;

    NSDictionary *bleDevices = [BSJSONParser dictFromJSONFile:@"bleDevices"];
    // http://stackoverflow.com/questions/10178293/how-to-get-list-of-available-bluetooth-devices?rq=1
    
    BOOL didStartScanning = NO;
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:15];
    
    while ( (!bsLeDiscovery.foundPeripherals
             || (0 == [bsLeDiscovery.foundPeripherals count]) )
           && [[timeoutDate laterDate:[NSDate date]] isEqualToDate:timeoutDate] ) {
        
        NSLog(@"In while loop.");
        NSLog(@"foundPeripherals %@", bsLeDiscovery.foundPeripherals);
        NSLog(@"%@ centralManager.state %ld", bsLeDiscovery.centralManager,
              bsLeDiscovery.centralManager.state);

        if(CBManagerStatePoweredOn != bsLeDiscovery.centralManager.state) {
            NSLog(@"still not powered on");
        } else {
            NSLog(@"CBManagerStatePoweredOn");
            // centralManager is powered on, ok to scan and retrieve
            // http://stackoverflow.com/questions/17118534/when-would-cbcentralmanagers-state-ever-be-powered-on-but-still-give-me-a-not?rq=1
            
            if(!didStartScanning) {
                //[bsLeDiscovery startScanningForUUIDString:expectedIdentifierString];
                //[bsLeDiscovery startScanningForUUIDString:@"180A"];
                [bsLeDiscovery startScanningForUUIDString:nil];
                didStartScanning = YES;
            }
        }
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    // cast id to BSBlePeripheral*
    BSBlePeripheral *bsBlePeripheral = (BSBlePeripheral *)[bsLeDiscovery.foundPeripherals firstObject];
    NSLog(@"foundPeripherals %@", bsLeDiscovery.foundPeripherals);

    // Assume iOS device will find at least one peripheral
    XCTAssertNotNil(bsBlePeripheral);
    NSString *UUIDString = [bsBlePeripheral.peripheral.identifier UUIDString];
    NSString *peripheralName = bsBlePeripheral.peripheral.name;

    // Assume the first peripheral is in this predefined list
    //
    bool foundFeit0 = ([bleDevices[@"feit0"][@"identifier"] isEqualToString:UUIDString]
                      && [bleDevices[@"feit0"][@"name"] isEqualToString:peripheralName]);
    bool foundFeit1 = ([bleDevices[@"feit1"][@"identifier"] isEqualToString:UUIDString]
                      && [bleDevices[@"feit1"][@"name"] isEqualToString:peripheralName]);
    bool foundFeit2 = ([bleDevices[@"feit2"][@"identifier"] isEqualToString:UUIDString]
                      && [bleDevices[@"feit2"][@"name"] isEqualToString:peripheralName]);
    bool foundFeit3 = ([bleDevices[@"feit3"][@"identifier"] isEqualToString:UUIDString]
                      && [bleDevices[@"feit3"][@"name"] isEqualToString:peripheralName]);

    bool foundFlex = ([bleDevices[@"flex"][@"identifier"] isEqualToString:UUIDString]
                      && [bleDevices[@"flex"][@"name"] isEqualToString:peripheralName]);

    bool foundOne = ([bleDevices[@"one"][@"identifier"] isEqualToString:UUIDString]
                     && [bleDevices[@"one"][@"name"]
                      isEqualToString:peripheralName]);
    
    bool foundRaspberryPi = ([bleDevices[@"raspberry_pi"][@"identifier"] isEqualToString:UUIDString]
                             && [[NSNull null] isEqual:peripheralName]);
    
    bool foundRedBear = ([bleDevices[@"redbearshield"][@"identifier"]
                          isEqualToString:UUIDString]
                         && [bleDevices[@"redbearshield"][@"name"]
                          isEqualToString:peripheralName]);
    
    bool foundSensorTag = ([bleDevices[@"sensortag"][@"identifier"]
                            isEqualToString:UUIDString]
                           && [bleDevices[@"sensortag"][@"name"]
                            isEqualToString:peripheralName]);
    
    XCTAssertTrue(foundFeit0 || foundFeit1 || foundFeit2 || foundFeit3
                  || foundFlex
                  || foundOne
                  || foundRaspberryPi
                  || foundRedBear
                  || foundSensorTag);
}

#pragma mark - test Connect/Disconnect
// This test blocks the main thread.
- (void)testConnectAndDisconnect {
    
    // If test exits with device still connected, Xcode warns
    // CoreBluetooth[WARNING] <CBPeripheral: 0x15e955d0 identifier = DDAB0207-5E10-2902-5B03-CA3F0F466B40, Name = "BLE Shield", state = connected> is being dealloc'ed while connected
    // Combine test connect and disconnect into one test.
    
    // http://stackoverflow.com/questions/18970247/cbcentralmanager-changes-for-ios-7
    dispatch_queue_t centralQueue = dispatch_queue_create("com.beepscore.central_manager", DISPATCH_QUEUE_SERIAL);
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:centralQueue];
    NSNotificationCenter *fakeNotificationCenter = [[NSNotificationCenter alloc] init];
    
    BSLeDiscovery *bsLeDiscovery = [[BSLeDiscovery alloc]
                                    initWithCentralManager:centralManager
                                    foundPeripherals:@[]
                                    connectedServices:nil
                                    notificationCenter:fakeNotificationCenter];
    
    BSBlePeripheral *bsBlePeripheral = nil;
    
    BOOL didStartScanning = NO;
    BOOL didCallConnect = NO;
    BOOL didCallDisconnect = NO;
    BOOL isConnected = NO;
    
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:15];
    
    // test connect
    while (!isConnected
           && (NSOrderedDescending != [[NSDate date] compare: timeoutDate]) ) {
        NSLog(@"connect not timed out");
        sleep(1);
        
        if(CBManagerStatePoweredOn != bsLeDiscovery.centralManager.state) {
            NSLog(@"not powered on");
            NSLog(@"%@ centralManager.state %ld", bsLeDiscovery.centralManager,
                         bsLeDiscovery.centralManager.state);
        } else {
            // centralManager is powered on, ok to scan and retrieve
            // http://stackoverflow.com/questions/17118534/when-would-cbcentralmanagers-state-ever-be-powered-on-but-still-give-me-a-not?rq=1
            NSLog(@"CBManagerStatePoweredOn");
            
            if(!didStartScanning) {
                [bsLeDiscovery startScanningForUUIDString:nil];
                didStartScanning = YES;
            }
            
            if( !bsLeDiscovery.foundPeripherals
               || ([@[] isEqual:bsLeDiscovery.foundPeripherals]) ) {
                NSLog(@"foundPeripherals nil or empty");
            } else {
                // foundPeripherals has at least one peripheral
                NSLog(@"foundPeripherals has at least one peripheral");
                bsBlePeripheral = [bsLeDiscovery.foundPeripherals firstObject];
                
                if (!didCallConnect) {
                    NSLog(@"calling connectPeripheral");
                    [bsLeDiscovery connectPeripheral:bsBlePeripheral.peripheral];
                    didCallConnect = YES;
                }
                
                if (CBPeripheralStateConnected == bsBlePeripheral.peripheral.state) {
                    isConnected = YES;
                }
            }
        }
    }
    XCTAssert((CBPeripheralStateConnected == bsBlePeripheral.peripheral.state),
              @"Connect failed.");
    
    // test disconnect
    timeoutDate = [NSDate dateWithTimeIntervalSinceNow:15];
    while (isConnected
           && (NSOrderedDescending != [[NSDate date] compare: timeoutDate]) ) {
        NSLog(@"disconnect not timed out");
        sleep(1);
        
        if (!didCallDisconnect) {
            NSLog(@"calling disconnectPeripheral");
            [bsLeDiscovery disconnectPeripheral:bsBlePeripheral.peripheral];
            didCallDisconnect = YES;
        }
        
        if (CBPeripheralStateDisconnected == bsBlePeripheral.peripheral.state) {
            isConnected = NO;
        }
    }
    XCTAssert((CBPeripheralStateDisconnected == bsBlePeripheral.peripheral.state),
              @"Disconnect failed.");
}

# pragma mark - test post notifications
- (void)testCentralManagerOffDidUpdateStatePostsBleDiscoveryDidRefreshNotification
{
    id mockNotificationCenter = [OCMockObject mockForClass:[NSNotificationCenter class]];

    BSStubCBCentralManager *stubCentralManager = [[BSStubCBCentralManager alloc] init];
    stubCentralManager.state = CBManagerStatePoweredOff;

    self.bsLeDiscovery = [[BSLeDiscovery alloc]
                          initWithCentralManager:(CBCentralManager *)stubCentralManager
                          foundPeripherals:nil
                          connectedServices:nil
                          notificationCenter:mockNotificationCenter];

    [[mockNotificationCenter expect] postNotificationName:kBleDiscoveryDidRefreshNotification
                                                   object:self.bsLeDiscovery
                                                 userInfo:nil];

    [self.bsLeDiscovery centralManagerDidUpdateState:(CBCentralManager *)stubCentralManager];
    
    // Verify all stubbed or expected methods were called.
    [mockNotificationCenter verify];
}

- (void)testCentralManagerOffDidUpdateStatePostsBleDiscoveryStatePoweredOffNotification
{
    // use nice mock to ignore un-expected method calls
    id mockNotificationCenter = [OCMockObject niceMockForClass:[NSNotificationCenter class]];

    BSStubCBCentralManager *stubCentralManager = [[BSStubCBCentralManager alloc] init];
    stubCentralManager.state = CBManagerStatePoweredOff;

    self.bsLeDiscovery = [[BSLeDiscovery alloc]
                          initWithCentralManager:(CBCentralManager *)stubCentralManager
                          foundPeripherals:nil
                          connectedServices:nil
                          notificationCenter:mockNotificationCenter];

    [[mockNotificationCenter expect] postNotificationName:kBleDiscoveryStatePoweredOffNotification
                                                   object:self.bsLeDiscovery
                                                 userInfo:nil];

    [self.bsLeDiscovery centralManagerDidUpdateState:(CBCentralManager *)stubCentralManager];
    
    // Verify all stubbed or expected methods were called.
    [mockNotificationCenter verify];
}

- (void)testCentralManagerOnDidUpdateStatePostsBleDiscoveryDidRefreshNotification
{
    id mockNotificationCenter = [OCMockObject mockForClass:[NSNotificationCenter class]];

    BSStubCBCentralManager *stubCentralManager = [[BSStubCBCentralManager alloc] init];
    stubCentralManager.state = CBManagerStatePoweredOn;

    self.bsLeDiscovery = [[BSLeDiscovery alloc]
                          initWithCentralManager:(CBCentralManager *)stubCentralManager
                          foundPeripherals:nil
                          connectedServices:nil
                          notificationCenter:mockNotificationCenter];

    [[mockNotificationCenter expect] postNotificationName:kBleDiscoveryDidRefreshNotification
                                                   object:self.bsLeDiscovery
                                                 userInfo:nil];

    [self.bsLeDiscovery centralManagerDidUpdateState:(CBCentralManager *)stubCentralManager];
    
    // Verify all stubbed or expected methods were called.
    [mockNotificationCenter verify];
}

//- (void)testCentralManagerDidConnectPeripheralPostsBleDiscoveryDidConnectPeripheralNotification
//{
//    id mockNotificationCenter = [OCMockObject mockForClass:[NSNotificationCenter class]];
//
//    BSStubCBCentralManager *stubCentralManager = [[BSStubCBCentralManager alloc] init];
//    stubCentralManager.state = CBManagerStatePoweredOn;
//
//    self.bsLeDiscovery = [[BSLeDiscovery alloc]
//                          initWithCentralManager:(CBCentralManager *)stubCentralManager
//                          foundPeripherals:nil
//                          connectedServices:nil
//                          notificationCenter:mockNotificationCenter];
//
//    CBPeripheral *peripheral = [[CBPeripheral alloc] init];
//    NSDictionary *fakeUserInfo = @{ @"peripheral" : peripheral};
//    [[mockNotificationCenter expect]
//     postNotificationName:kBleDiscoveryDidConnectPeripheralNotification
//     object:self.bsLeDiscovery
//     userInfo:fakeUserInfo];
//
//    [self.bsLeDiscovery centralManager:(CBCentralManager *)stubCentralManager
//                  didConnectPeripheral:peripheral];
//
//    // Verify all stubbed or expected methods were called.
//    [mockNotificationCenter verify];
//}

- (void)testCentralManagerDidDisconnectPeripheralPostsBleDiscoveryDidDisconnectPeripheralNotification
{
    id mockNotificationCenter = [OCMockObject mockForClass:[NSNotificationCenter class]];
    
    BSStubCBCentralManager *stubCentralManager = [[BSStubCBCentralManager alloc] init];
    stubCentralManager.state = CBManagerStatePoweredOn;
    
    self.bsLeDiscovery = [[BSLeDiscovery alloc]
                          initWithCentralManager:(CBCentralManager *)stubCentralManager
                          foundPeripherals:nil
                          connectedServices:nil
                          notificationCenter:mockNotificationCenter];
    
    // Instantiating a CBPeripheral made program crash.
    // So use an NSObject and cast it.
    // CBPeripheral *fakePeripheral = [[CBPeripheral alloc] init];
    NSObject *fakePeripheral = [[NSObject alloc] init];
    NSError *fakeError = [[NSError alloc] init];
    NSDictionary *fakeUserInfo = @{ @"peripheral" : fakePeripheral,
                                    @"error" : fakeError };
    [[mockNotificationCenter expect]
     postNotificationName:kBleDiscoveryDidDisconnectPeripheralNotification
     object:self.bsLeDiscovery
     userInfo:fakeUserInfo];
    
    [self.bsLeDiscovery centralManager:(CBCentralManager *)stubCentralManager
               didDisconnectPeripheral:(CBPeripheral *)fakePeripheral
                                 error:fakeError];
    
    // Verify all stubbed or expected methods were called, and called on main queue.
    [mockNotificationCenter verify];
}

@end
