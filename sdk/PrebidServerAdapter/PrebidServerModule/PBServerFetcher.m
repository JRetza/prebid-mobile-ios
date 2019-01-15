
/*   Copyright 2017 Prebid.org, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "PBLogging.h"
#import "PBServerFetcher.h"

@interface PBServerFetcher ()

@property (nonatomic, strong) NSMutableArray *requestTIDs;

@end

@implementation PBServerFetcher

+ (instancetype)sharedInstance {
    static dispatch_once_t _dispatchHandle = 0;
    static PBServerFetcher *_sharedInstance = nil;
    
    dispatch_once(&_dispatchHandle, ^{
        if (_sharedInstance == nil)
            _sharedInstance = [[PBServerFetcher alloc] init];
        
    });
    return _sharedInstance;
}

- (void)makeBidRequest:(NSURLRequest *)request withCompletionHandler:(void (^)(NSDictionary *, NSError *))completionHandler {
    PBLogDebug(@"Bid request to Prebid Server: %@ params: %@", request.URL.absoluteString, [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);
    NSDictionary *params = [NSJSONSerialization JSONObjectWithData:[request HTTPBody]
                                                           options:kNilOptions
                                                             error:nil];
    // Map request tids to ad unit codes to check to make sure response lines up
    if (self.requestTIDs == nil) {
        self.requestTIDs = [[NSMutableArray alloc] init];
    }
    @synchronized(self.requestTIDs) {
        if(params[@"tid"] != nil){
            [self.requestTIDs addObject:params[@"tid"]];
        }
    }

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (response != nil && data.length > 0) {
                                   PBLogDebug(@"Bid response from Prebid Server: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                   //NSDictionary *adUnitToBids = [self processData:data];
                                   //NSString * str =@"{\"id\":\"C3713F94-9187-4900-A83A-40F73AFA7623\",\"seatbid\":[{\"bid\":[{\"id\":\"14\",\"impid\":\"top1\",\"price\":0.830682,\"adm\":\"    <script type=\\\"text/javascript\\\">\\n      rubicon_cb = Math.random(); rubicon_rurl = document.referrer; if(top.location==document.location){rubicon_rurl = document.location;} rubicon_rurl = escape(rubicon_rurl);\\n      window.rubicon_ad = \\\"3361275\\\" + \\\".\\\" + \\\"js\\\";\\n      window.rubicon_creative = \\\"3441585\\\" + \\\".\\\" + \\\"js\\\";\\n    </script>\\n<div data-rp-type=\\\"trp-display-creative\\\" data-rp-impression-id=\\\"4a034376-f5d7-462d-a26c-25030964bae1\\\" data-rp-aqid=\\\"2676:27770057\\\" data-rp-acct-id=\\\"12108\\\">\\n<div style=\\\"width: 0; height: 0; overflow: hidden;\\\"><img border=\\\"0\\\" width=\\\"1\\\" height=\\\"1\\\" src=\\\"https://beacon-eu-ams3.rubiconproject.com/beacon/d/4a034376-f5d7-462d-a26c-25030964bae1?oo=0&accountId=12108&siteId=212486&zoneId=1057092&sizeId=15&e=6A1E40E384DA563B9372CAAFC0D470D1A50AA0F7A4D4228D67EF1D675C22FAC1D3E4557C0FA1E45B0B8F0FBC9EC91AA77A3220A15E3EC91D64A585F88F53E0A7062FF0113E8E49E37E0B2710D32638617E99A65DAFAF52C279A4F59D60CF46CFA734992932A656C8EFF5C7CFD889081ADFFA16DC2C67B308FB030475296D9C4980725D6EEF55E528B7FE1C3A83D6FFBAA9C190A15A7267CBF321F5C99A1FFBFEBA18A26F7EDACAEC9688F31B24BF1DECB342695E712E7B0FEEADD8827CBB321288EBACD60D0CF102\\\" alt=\\\"\\\" /></div>\\n\\n<script type='text/javascript' src='https://track.adform.net/adfscript/?bn=27770057;rtbwp=19ECB72C7BC91339;rtbdata=Jud11cm-h96OQ4QDsBlLEfu7wooAE8RQXYxEpfvk0w84tm7Msn8EkgB1zg_DY3amssa0dHjc9Lib4oYqdY7v45TGlDN4VGHtyLkM3nz-GraE7n2uOiu1IZQhuVz-tsN7sAAaMkpXR5De46SIm7mPsrcClznSq710VHfc48XFdYj8-cu4L9Ke189pa2MPUR74kydAmzwn2RLbWsXiTr6uu64ieahEoIq6rrRmRp9cx40KkHzcBXaf5L-hI098mhUAjKvZQ6ujEUjfdbg6Uyq8iCf8QNAgzq93BGhkKubR_JYcww3PMQ844XmmqAj7MIzcQeEimShqzcc1;OOBClickTrack=http://beacon-nf.rubiconproject.com/beacon/v2/t/0/4a034376-f5d7-462d-a26c-25030964bae1/'></script>\\n<div style=\\\"height:0px;width:0px;overflow:hidden\\\"><iframe src=\\\"https://eus.rubiconproject.com/usync.html?&geo=eu&co=nl\\\" frameborder=\\\"0\\\" marginwidth=\\\"0\\\" marginheight=\\\"0\\\" scrolling=\\\"NO\\\" width=\\\"0\\\" height=\\\"0\\\" style=\\\"height:0px;width:0px\\\"></iframe></div></div>\\n\\n\",\"adomain\":[\"atlascollege.nl\"],\"crid\":\"2676:27770057\",\"w\":300,\"h\":250,\"ext\":{\"prebid\":{\"targeting\":{\"hb_bidder\":\"rubicon\",\"hb_bidder_rubicon\":\"rubicon\",\"hb_env\":\"mobile-app\",\"hb_env_rubicon\":\"mobile-app\",\"hb_pb\":\"0.80\",\"hb_pb_rubicon\":\"0.80\",\"hb_size\":\"300x250\",\"hb_size_rubicon\":\"300x250\"},\"type\":\"banner\"},\"bidder\":{\"rp\":{\"advid\":623970,\"targeting\":[{\"key\":\"rpfl_12108\",\"values\":[\"15_tier0070\"]}],\"mime\":\"text\\/html\",\"size_id\":15}}}}],\"seat\":\"rubicon\"},{\"bid\":[{\"id\":\"9005727932560783124\",\"impid\":\"top1\",\"price\":0.02306,\"adm\":\"<script src=\\\"https://ams1-ib.adnxs.com/ab?test=1&referrer=itunes.apple.com%2Fus%2Fapp%2Fde-volkskrant%2Fid418873064&e=wqT_3QL9CPBCfQQAAAMA1gAFAQjc1uLhBRCRyOvO2dvx430YrNnZn77j8pZAKjYJ6Q5iZwqdlz8R6Q5iZwqdlz8ZAAAA4FG4nj8h6Q0SACkRJAAxERvwdTDUwsIGOOQHQOQHSAJQm8ysM1ipmC1gAGit2Ed4zpAFgAEBigEDVVNEkgEDRVVSmAHAAqABMqgBAbABALgBAsABBMgBAtABANgBAOABAfABAIoCPHVmKCdhJywgMTM0MTg2MCwgMTU0NzIxNzc1Nik7dWYoJ3IBHSAwNzY4NTQwMywyHwD0BAGSAvUBIVFUeUVSUWpFNzh3TUVKdk1yRE1ZQUNDcG1DMHdBRGdBUUFSSTVBZFExTUxDQmxnQVlJd0ZhQUJ3bEFGNDdpMkFBWlFCaUFIdUxaQUJBWmdCQWFBQkFhZ0JBN0FCQUxrQmtlOEs4T0Y2bERfQkFRRTZvZlVQblpjX3lRSHFYaVhURGlQVVA5a0Jfa1A2N2V2QTZ6X2dBUUQxQVFBQUFBQ1lBZ0NnQWdDMUFnQUFBQUM5QWdBQUFBREFBZ0RJQWdEZ0FnRG9BZ0Q0QWdDQUF3R1FBd0NZQXdHb0E4VHZ6QXk2QXdsQlRWTXhPalF4TnpmZ0E4b0WaAmEhX3hSbFhBakUu-ADYcVpndElBUW9BREY3Rks1SDRYcVVQem9KUVUxVE1UbzBNVGMzUU1vRVNmNUQtdTNyd09zX1VRQQGZBQEAVx0M8FjYAt4B4ALgrDzqAjFpdHVuZXMuYXBwbGUuY29tL3VzL2FwcC9kZS12b2xrc2tyYW50L2lkNDE4ODczMDY08gITCg9DVVNUT01fTU9ERUxfSUQSAPICGgoWQy4WACBMRUFGX05BTUUBHQweChpDMh0A9BgBQVNUX01PRElGSUVEEgCAAwCIAwGQAwCYAxSgAwGqAwDAA6wCyAMA0gMoCAASJGMxN2JlYTIxLTAxMzktNGY0MC05ZDIwLThkMjMyZTQ3ZGJhNdIDLAgCEihhNTY1YzQwNmRhYWNlYjBmODE0MjNjZmIzZDhiYzdjMGFkNDYyMGM10gMkCAQSIGEzMzc3MDE1NzYzZjQxMzI0M2VhMmM5NmExNjBmNzAz2AOS_ZMB4AMA6AMC-AMAgAQAkgQJL29wZW5ydGIymAQAogQNODEuMTcxLjgxLjE2MKgEuiGyBAwIABAAGAAgADAAOAC4BADABADIBADSBA05OTYjQU1TMTo0MTc32gQCCAHgBADwBJvMrDOCBQk0MTgpZSCIBQGYBQCgBf8RAbgBqgUkQzM3MTNGOTQtOTE4Ny00OTAwLUE4M0EtNDBGNzNBRkE3NjIzwAUAyQUAAAECFPA_0gUJCQEKAQFs2AUB4AUB8AWoNPoFBAgAEACQBgCYBgC4BgDBBgEgLAAA8D_IBgDaBhYKEAkQNAAAAAAAAAAAAAAQABgA&s=1931b469e06462292afc05e2bc0ef946701f8f83&pp=${AUCTION_PRICE}\\\"></script>\",\"adid\":\"107685403\",\"adomain\":[\"webads.nl\"],\"iurl\":\"https://ams1-ib.adnxs.com/cr?id=107685403\",\"cid\":\"996\",\"crid\":\"107685403\",\"cat\":[\"IAB3-1\"],\"w\":320,\"h\":50,\"ext\":{\"prebid\":{\"targeting\":{\"hb_bidder_appnexus\":\"appnexus\",\"hb_env_appnexus\":\"mobile-app\",\"hb_pb_appnexus\":\"0.00\",\"hb_size_appnexus\":\"320x50\"},\"type\":\"banner\"},\"bidder\":{\"appnexus\":{\"brand_id\":6696,\"auction_id\":9063431430177743889,\"bidder_id\":2,\"bid_ad_type\":0}}}}],\"seat\":\"appnexus\"}],\"ext\":{\"debug\":{\"httpcalls\":{\"appnexus\":[{\"uri\":\"http://ib.adnxs.com/openrtb2\",\"requestbody\":\"{\\\"id\\\":\\\"C3713F94-9187-4900-A83A-40F73AFA7623\\\",\\\"imp\\\":[{\\\"id\\\":\\\"top1\\\",\\\"banner\\\":{\\\"format\\\":[{\\\"w\\\":320,\\\"h\\\":50},{\\\"w\\\":320,\\\"h\\\":100},{\\\"w\\\":320,\\\"h\\\":240},{\\\"w\\\":300,\\\"h\\\":250}],\\\"w\\\":320,\\\"h\\\":50},\\\"displaymanagerver\\\":\\\"prebid-mobile-0.5.3\\\",\\\"secure\\\":1,\\\"ext\\\":{\\\"appnexus\\\":{\\\"placement_id\\\":13672788,\\\"private_sizes\\\":[{\\\"w\\\":320,\\\"h\\\":50},{\\\"w\\\":320,\\\"h\\\":100},{\\\"w\\\":320,\\\"h\\\":240},{\\\"w\\\":300,\\\"h\\\":250}]}}}],\\\"app\\\":{\\\"bundle\\\":\\\"be.persgroep.vk\\\",\\\"ver\\\":\\\"1.0\\\",\\\"publisher\\\":{\\\"id\\\":\\\"0\\\"},\\\"ext\\\":{\\\"prebid\\\":{\\\"version\\\":\\\"0.5.3\\\",\\\"source\\\":\\\"prebid-mobile\\\"}}},\\\"device\\\":{\\\"ua\\\":\\\"Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/16B91\\\",\\\"ip\\\":\\\"81.171.81.160\\\",\\\"make\\\":\\\"Apple\\\",\\\"model\\\":\\\"x86_64\\\",\\\"os\\\":\\\"iOS\\\",\\\"osv\\\":\\\"12.1\\\",\\\"h\\\":896,\\\"w\\\":414,\\\"pxratio\\\":2,\\\"connectiontype\\\":1,\\\"ifa\\\":\\\"C17BEA21-0139-4F40-9D20-8D232E47DBA5\\\"},\\\"user\\\":{\\\"gender\\\":\\\"O\\\"},\\\"test\\\":1,\\\"at\\\":1,\\\"source\\\":{\\\"tid\\\":\\\"123\\\"},\\\"ext\\\":{\\\"prebid\\\":{\\\"targeting\\\":{}}}}\",\"responsebody\":\"{\\\"id\\\":\\\"C3713F94-9187-4900-A83A-40F73AFA7623\\\",\\\"seatbid\\\":[{\\\"bid\\\":[{\\\"id\\\":\\\"9005727932560783124\\\",\\\"impid\\\":\\\"top1\\\",\\\"price\\\":0.023060,\\\"adid\\\":\\\"107685403\\\",\\\"adm\\\":\\\"\\u003cscript src=\\\\\\\"https:\\\\/\\\\/ams1-ib.adnxs.com\\\\/ab?test=1\\u0026referrer=itunes.apple.com%2Fus%2Fapp%2Fde-volkskrant%2Fid418873064\\u0026e=wqT_3QL9CPBCfQQAAAMA1gAFAQjc1uLhBRCRyOvO2dvx430YrNnZn77j8pZAKjYJ6Q5iZwqdlz8R6Q5iZwqdlz8ZAAAA4FG4nj8h6Q0SACkRJAAxERvwdTDUwsIGOOQHQOQHSAJQm8ysM1ipmC1gAGit2Ed4zpAFgAEBigEDVVNEkgEDRVVSmAHAAqABMqgBAbABALgBAsABBMgBAtABANgBAOABAfABAIoCPHVmKCdhJywgMTM0MTg2MCwgMTU0NzIxNzc1Nik7dWYoJ3IBHSAwNzY4NTQwMywyHwD0BAGSAvUBIVFUeUVSUWpFNzh3TUVKdk1yRE1ZQUNDcG1DMHdBRGdBUUFSSTVBZFExTUxDQmxnQVlJd0ZhQUJ3bEFGNDdpMkFBWlFCaUFIdUxaQUJBWmdCQWFBQkFhZ0JBN0FCQUxrQmtlOEs4T0Y2bERfQkFRRTZvZlVQblpjX3lRSHFYaVhURGlQVVA5a0Jfa1A2N2V2QTZ6X2dBUUQxQVFBQUFBQ1lBZ0NnQWdDMUFnQUFBQUM5QWdBQUFBREFBZ0RJQWdEZ0FnRG9BZ0Q0QWdDQUF3R1FBd0NZQXdHb0E4VHZ6QXk2QXdsQlRWTXhPalF4TnpmZ0E4b0WaAmEhX3hSbFhBakUu-ADYcVpndElBUW9BREY3Rks1SDRYcVVQem9KUVUxVE1UbzBNVGMzUU1vRVNmNUQtdTNyd09zX1VRQQGZBQEAVx0M8FjYAt4B4ALgrDzqAjFpdHVuZXMuYXBwbGUuY29tL3VzL2FwcC9kZS12b2xrc2tyYW50L2lkNDE4ODczMDY08gITCg9DVVNUT01fTU9ERUxfSUQSAPICGgoWQy4WACBMRUFGX05BTUUBHQweChpDMh0A9BgBQVNUX01PRElGSUVEEgCAAwCIAwGQAwCYAxSgAwGqAwDAA6wCyAMA0gMoCAASJGMxN2JlYTIxLTAxMzktNGY0MC05ZDIwLThkMjMyZTQ3ZGJhNdIDLAgCEihhNTY1YzQwNmRhYWNlYjBmODE0MjNjZmIzZDhiYzdjMGFkNDYyMGM10gMkCAQSIGEzMzc3MDE1NzYzZjQxMzI0M2VhMmM5NmExNjBmNzAz2AOS_ZMB4AMA6AMC-AMAgAQAkgQJL29wZW5ydGIymAQAogQNODEuMTcxLjgxLjE2MKgEuiGyBAwIABAAGAAgADAAOAC4BADABADIBADSBA05OTYjQU1TMTo0MTc32gQCCAHgBADwBJvMrDOCBQk0MTgpZSCIBQGYBQCgBf8RAbgBqgUkQzM3MTNGOTQtOTE4Ny00OTAwLUE4M0EtNDBGNzNBRkE3NjIzwAUAyQUAAAECFPA_0gUJCQEKAQFs2AUB4AUB8AWoNPoFBAgAEACQBgCYBgC4BgDBBgEgLAAA8D_IBgDaBhYKEAkQNAAAAAAAAAAAAAAQABgA\\u0026s=1931b469e06462292afc05e2bc0ef946701f8f83\\u0026pp=${AUCTION_PRICE}\\\\\\\"\\u003e\\u003c\\\\/script\\u003e\\\",\\\"adomain\\\":[\\\"webads.nl\\\"],\\\"iurl\\\":\\\"https:\\\\/\\\\/ams1-ib.adnxs.com\\\\/cr?id=107685403\\\",\\\"cid\\\":\\\"996\\\",\\\"crid\\\":\\\"107685403\\\",\\\"cat\\\":[\\\"IAB3-1\\\"],\\\"h\\\":50,\\\"w\\\":320,\\\"ext\\\":{\\\"appnexus\\\":{\\\"brand_id\\\":6696,\\\"auction_id\\\":9063431430177743889,\\\"bidder_id\\\":2,\\\"bid_ad_type\\\":0}}}],\\\"seat\\\":\\\"996\\\"}],\\\"bidid\\\":\\\"6396733005316768957\\\",\\\"cur\\\":\\\"USD\\\"}\",\"status\":200}],\"rubicon\":[{\"uri\":\"http://exapi-eu.rubiconproject.com/a/api/exchange.json?tk_sdc=eu\\u0026tk_xint=persgroep-pbs\",\"requestbody\":\"{\\\"id\\\":\\\"C3713F94-9187-4900-A83A-40F73AFA7623\\\",\\\"imp\\\":[{\\\"id\\\":\\\"top1\\\",\\\"banner\\\":{\\\"format\\\":[{\\\"w\\\":320,\\\"h\\\":50},{\\\"w\\\":320,\\\"h\\\":100},{\\\"w\\\":320,\\\"h\\\":240},{\\\"w\\\":300,\\\"h\\\":250}],\\\"w\\\":320,\\\"h\\\":50,\\\"ext\\\":{\\\"rp\\\":{\\\"size_id\\\":15,\\\"alt_size_ids\\\":[43,117],\\\"mime\\\":\\\"text/html\\\"}}},\\\"secure\\\":1,\\\"ext\\\":{\\\"rp\\\":{\\\"zone_id\\\":1057092,\\\"target\\\":null,\\\"track\\\":{\\\"mint\\\":\\\"\\\",\\\"mint_version\\\":\\\"\\\"}}}}],\\\"app\\\":{\\\"bundle\\\":\\\"be.persgroep.vk\\\",\\\"ver\\\":\\\"1.0\\\",\\\"publisher\\\":{\\\"ext\\\":{\\\"rp\\\":{\\\"account_id\\\":12108}}},\\\"ext\\\":{\\\"rp\\\":{\\\"site_id\\\":212486}}},\\\"device\\\":{\\\"ua\\\":\\\"Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/16B91\\\",\\\"ip\\\":\\\"81.171.81.160\\\",\\\"make\\\":\\\"Apple\\\",\\\"model\\\":\\\"x86_64\\\",\\\"os\\\":\\\"iOS\\\",\\\"osv\\\":\\\"12.1\\\",\\\"h\\\":896,\\\"w\\\":414,\\\"pxratio\\\":2,\\\"connectiontype\\\":1,\\\"ifa\\\":\\\"C17BEA21-0139-4F40-9D20-8D232E47DBA5\\\",\\\"ext\\\":{\\\"rp\\\":{\\\"pixelratio\\\":2}}},\\\"user\\\":{\\\"gender\\\":\\\"O\\\",\\\"ext\\\":{\\\"rp\\\":{\\\"target\\\":null},\\\"digitrust\\\":null}},\\\"test\\\":1,\\\"at\\\":1,\\\"source\\\":{\\\"tid\\\":\\\"123\\\"},\\\"ext\\\":{\\\"prebid\\\":{\\\"targeting\\\":{}}}}\",\"responsebody\":\"{\\\"id\\\":\\\"C3713F94-9187-4900-A83A-40F73AFA7623\\\",\\\"bidid\\\":\\\"4a034376-f5d7-462d-a26c-25030964bae1\\\",\\\"seatbid\\\":[{\\\"seat\\\":\\\"2676:8192::232506\\\",\\\"buyer\\\":\\\"2676\\\",\\\"bid\\\":[{\\\"id\\\":\\\"14\\\",\\\"impid\\\":\\\"top1\\\",\\\"price\\\":0.830682,\\\"adm\\\":\\\"    \\u003cscript type=\\\\\\\"text\\\\/javascript\\\\\\\"\\u003e\\\\n      rubicon_cb = Math.random(); rubicon_rurl = document.referrer; if(top.location==document.location){rubicon_rurl = document.location;} rubicon_rurl = escape(rubicon_rurl);\\\\n      window.rubicon_ad = \\\\\\\"3361275\\\\\\\" + \\\\\\\".\\\\\\\" + \\\\\\\"js\\\\\\\";\\\\n      window.rubicon_creative = \\\\\\\"3441585\\\\\\\" + \\\\\\\".\\\\\\\" + \\\\\\\"js\\\\\\\";\\\\n    \\u003c\\\\/script\\u003e\\\\n\\u003cdiv data-rp-type=\\\\\\\"trp-display-creative\\\\\\\" data-rp-impression-id=\\\\\\\"4a034376-f5d7-462d-a26c-25030964bae1\\\\\\\" data-rp-aqid=\\\\\\\"2676:27770057\\\\\\\" data-rp-acct-id=\\\\\\\"12108\\\\\\\"\\u003e\\\\n\\u003cdiv style=\\\\\\\"width: 0; height: 0; overflow: hidden;\\\\\\\"\\u003e\\u003cimg border=\\\\\\\"0\\\\\\\" width=\\\\\\\"1\\\\\\\" height=\\\\\\\"1\\\\\\\" src=\\\\\\\"https:\\\\/\\\\/beacon-eu-ams3.rubiconproject.com\\\\/beacon\\\\/d\\\\/4a034376-f5d7-462d-a26c-25030964bae1?oo=0\\u0026accountId=12108\\u0026siteId=212486\\u0026zoneId=1057092\\u0026sizeId=15\\u0026e=6A1E40E384DA563B9372CAAFC0D470D1A50AA0F7A4D4228D67EF1D675C22FAC1D3E4557C0FA1E45B0B8F0FBC9EC91AA77A3220A15E3EC91D64A585F88F53E0A7062FF0113E8E49E37E0B2710D32638617E99A65DAFAF52C279A4F59D60CF46CFA734992932A656C8EFF5C7CFD889081ADFFA16DC2C67B308FB030475296D9C4980725D6EEF55E528B7FE1C3A83D6FFBAA9C190A15A7267CBF321F5C99A1FFBFEBA18A26F7EDACAEC9688F31B24BF1DECB342695E712E7B0FEEADD8827CBB321288EBACD60D0CF102\\\\\\\" alt=\\\\\\\"\\\\\\\" \\\\/\\u003e\\u003c\\\\/div\\u003e\\\\n\\\\n\\u003cscript type='text\\\\/javascript' src='https:\\\\/\\\\/track.adform.net\\\\/adfscript\\\\/?bn=27770057;rtbwp=19ECB72C7BC91339;rtbdata=Jud11cm-h96OQ4QDsBlLEfu7wooAE8RQXYxEpfvk0w84tm7Msn8EkgB1zg_DY3amssa0dHjc9Lib4oYqdY7v45TGlDN4VGHtyLkM3nz-GraE7n2uOiu1IZQhuVz-tsN7sAAaMkpXR5De46SIm7mPsrcClznSq710VHfc48XFdYj8-cu4L9Ke189pa2MPUR74kydAmzwn2RLbWsXiTr6uu64ieahEoIq6rrRmRp9cx40KkHzcBXaf5L-hI098mhUAjKvZQ6ujEUjfdbg6Uyq8iCf8QNAgzq93BGhkKubR_JYcww3PMQ844XmmqAj7MIzcQeEimShqzcc1;OOBClickTrack=http:\\\\/\\\\/beacon-nf.rubiconproject.com\\\\/beacon\\\\/v2\\\\/t\\\\/0\\\\/4a034376-f5d7-462d-a26c-25030964bae1\\\\/'\\u003e\\u003c\\\\/script\\u003e\\\\n\\u003cdiv style=\\\\\\\"height:0px;width:0px;overflow:hidden\\\\\\\"\\u003e\\u003ciframe src=\\\\\\\"https:\\\\/\\\\/eus.rubiconproject.com\\\\/usync.html?\\u0026geo=eu\\u0026co=nl\\\\\\\" frameborder=\\\\\\\"0\\\\\\\" marginwidth=\\\\\\\"0\\\\\\\" marginheight=\\\\\\\"0\\\\\\\" scrolling=\\\\\\\"NO\\\\\\\" width=\\\\\\\"0\\\\\\\" height=\\\\\\\"0\\\\\\\" style=\\\\\\\"height:0px;width:0px\\\\\\\"\\u003e\\u003c\\\\/iframe\\u003e\\u003c\\\\/div\\u003e\\u003c\\\\/div\\u003e\\\\n\\\\n\\\",\\\"adomain\\\":[\\\"atlascollege.nl\\\"],\\\"crid\\\":\\\"2676:27770057\\\",\\\"w\\\":300,\\\"h\\\":250,\\\"ext\\\":{\\\"rp\\\":{\\\"advid\\\":623970,\\\"targeting\\\":[{\\\"key\\\":\\\"rpfl_12108\\\",\\\"values\\\":[\\\"15_tier0070\\\"]}],\\\"mime\\\":\\\"text\\\\/html\\\",\\\"size_id\\\":15}}}]}],\\\"statuscode\\\":0}\",\"status\":200}]},\"resolvedrequest\":{\"id\":\"C3713F94-9187-4900-A83A-40F73AFA7623\",\"imp\":[{\"id\":\"top1\",\"banner\":{\"format\":[{\"w\":320,\"h\":50},{\"w\":320,\"h\":100},{\"w\":320,\"h\":240},{\"w\":300,\"h\":250}],\"w\":320,\"h\":50},\"secure\":1,\"ext\":{\"appnexus\":{\"placementId\":13672788,\"private_sizes\":[{\"w\":320,\"h\":50},{\"w\":320,\"h\":100},{\"w\":320,\"h\":240},{\"w\":300,\"h\":250}]},\"prebid\":{\"storedrequest\":{\"id\":\"pg-i-vk\"},\"targeting\":{}},\"rubicon\":{\"accountId\":12108,\"siteId\":212486,\"zoneId\":1057092,\"sizes\":[43,117,108,15]}}}],\"app\":{\"bundle\":\"be.persgroep.vk\",\"ver\":\"1.0\",\"publisher\":{\"id\":\"0\"},\"ext\":{\"prebid\":{\"version\":\"0.5.3\",\"source\":\"prebid-mobile\"}}},\"device\":{\"ua\":\"Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/16B91\",\"ip\":\"81.171.81.160\",\"make\":\"Apple\",\"model\":\"x86_64\",\"os\":\"iOS\",\"osv\":\"12.1\",\"h\":896,\"w\":414,\"pxratio\":2,\"connectiontype\":1,\"ifa\":\"C17BEA21-0139-4F40-9D20-8D232E47DBA5\"},\"user\":{\"gender\":\"O\"},\"test\":1,\"at\":1,\"source\":{\"tid\":\"123\"},\"ext\":{\"prebid\":{\"targeting\":{}}}}},\"responsetimemillis\":{\"appnexus\":332,\"rubicon\":157}}}";
                                   //data = [str dataUsingEncoding:NSUTF8StringEncoding];
                                   NSDictionary *openRTBAdUnitBidMap = [self processOpenRTBData:data];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                        completionHandler(openRTBAdUnitBidMap, nil);
                                   });
                               } else {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       completionHandler(nil, error);
                                   });
                               }
                           }];
}

- (NSDictionary *)processOpenRTBData:(NSData *)data {
    NSError *error;
    id object = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&error];
    if (error) {
        PBLogError(@"Error parsing ad server response");
        return [[NSMutableDictionary alloc] init];
    }
    if (!object) {
        return [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *adUnitToBidsMap = [[NSMutableDictionary alloc] init];
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *response = (NSDictionary *)object;
        if ([[response objectForKey:@"seatbid"] isKindOfClass:[NSArray class]]) {
            NSArray *seatbids = (NSArray *)[response objectForKey:@"seatbid"];
            for (id seatbid in seatbids) {
                if ([seatbid isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *seatbidDict = (NSDictionary *)seatbid;
                    if ([[seatbidDict objectForKey:@"bid"] isKindOfClass:[NSArray class]]) {
                        NSArray *bids = (NSArray *)[seatbidDict objectForKey:@"bid"];
                        for (id bid in bids) {
                            if ([bid isKindOfClass:[NSDictionary class]]) {
                                NSMutableDictionary *bidDict = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)bid];
                                [bidDict setObject:seatbid[@"seat"] forKey:@"seat"];
                                NSMutableArray *adUnitBids = [[NSMutableArray alloc] init];
                                if ([adUnitToBidsMap objectForKey:bidDict[@"impid"]] != nil) {
                                    adUnitBids = [adUnitToBidsMap objectForKey:bidDict[@"impid"]];
                                }
                                [adUnitBids addObject:bidDict];
                                [adUnitToBidsMap setObject:adUnitBids forKey:bidDict[@"impid"]];
                                
                                if ([[response objectForKey:@"ext"] isKindOfClass:[NSDictionary class]]) {
                                    NSDictionary *ext = (NSDictionary *)[response objectForKey:@"ext"];
                                    if ([[ext objectForKey:@"responsetimemillis"] isKindOfClass:[NSDictionary class]]) {
                                        NSDictionary *responsetimemillis= (NSDictionary *)[ext objectForKey:@"responsetimemillis"];
                                        
                                        if ([[responsetimemillis objectForKey:[seatbid objectForKey:@"seat"]] isKindOfClass:[NSNumber class]]) {
                                            [bidDict setObject:responsetimemillis[[seatbid objectForKey:@"seat"]] forKey:@"responsetime"];
                                        }
                                    }
                                    
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
        for (NSString* bidResults in [adUnitToBidsMap allKeys]) {
            if ([[response objectForKey:@"ext"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *ext = (NSDictionary *)[response objectForKey:@"ext"];
                if ([[ext objectForKey:@"responsetimemillis"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *responsetimemillis= (NSDictionary *)[ext objectForKey:@"responsetimemillis"];
                    for(NSString* bidderName in [responsetimemillis allKeys]){
                        BOOL found = false;
                        for (NSMutableDictionary* bid in[adUnitToBidsMap objectForKey:bidResults]) {
                            if ([bid[@"seat"] isEqualToString:bidderName]) {
                                found = true;
                                break;
                            }
                        }
                        if(!found){
                            NSMutableDictionary* bidDict = [[NSMutableDictionary alloc] init];
                            bidDict[@"seat"] = bidderName;
                            bidDict[@"responsetime"] = [responsetimemillis valueForKey:bidderName];
                            bidDict[@"responseType"] = @(2);
                            [[adUnitToBidsMap objectForKey:bidResults] addObject:bidDict];
                        }
                    }
                }
            }
        }
    }
    
    return adUnitToBidsMap;
}

// now need to handle OpenRTB response
- (NSDictionary *)processData:(NSData *)data {
    NSDictionary *bidMap = [[NSDictionary alloc] init];
    NSError *error;
    id object = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&error];
    if (error) {
        PBLogError(@"Error parsing ad server response");
        return [[NSMutableDictionary alloc] init];
    }
    if (!object) {
        return [[NSMutableDictionary alloc] init];
    }
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *response = (NSDictionary *)object;
        if ([[response objectForKey:@"status"] isKindOfClass:[NSString class]]) {
            NSString *status = (NSString *)[response objectForKey:@"status"];
            if ([status isEqualToString:@"OK"]) {
                // check to make sure the request tid matches the response tid
                NSString *responseTID = (NSString *)[response objectForKey:@"tid"];
                NSMutableArray *requestTIDsToDelete = [NSMutableArray array];
                @synchronized (self.requestTIDs) {
                    if ([self.requestTIDs containsObject:responseTID]) {
                        [requestTIDsToDelete addObject:responseTID];
                        bidMap = [self mapBidsToAdUnits:response];
                    } else {
                        PBLogError(@"Response tid did not match request tid %@", response);
                    }
                    [self.requestTIDs removeObjectsInArray:requestTIDsToDelete];
                }
            }
            else {
                PBLogError(@"Received bad status response from the ad server %@", response);
            }
        }
    } else {
        PBLogError(@"Unexpected response structure received from ad server %@", object);
    }
    return bidMap;
}

- (NSDictionary *)mapBidsToAdUnits:(NSDictionary *)responseDict {
    NSDictionary *response = (NSDictionary *)responseDict;
    
    NSMutableDictionary *adUnitToBidsMap = [[NSMutableDictionary alloc] init];
    if ([[response objectForKey:@"bids"] isKindOfClass:[NSArray class]]) {
        NSArray *bids = (NSArray *)[response objectForKey:@"bids"];
        [bids enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *bid = (NSDictionary *)obj;
                NSMutableArray *bidsArray = [adUnitToBidsMap objectForKey:bid[@"code"]];
                if (bidsArray) {
                    [bidsArray addObject:bid];
                    [adUnitToBidsMap setObject:bidsArray forKey:bid[@"code"]];
                } else {
                    NSMutableArray *newBidsArray = [[NSMutableArray alloc] initWithArray:@[bid]];
                    [adUnitToBidsMap setObject:newBidsArray forKey:bid[@"code"]];
                }
            }
        }];
        return adUnitToBidsMap;
    }
    
    return [[NSMutableDictionary alloc] init];
}

@end
