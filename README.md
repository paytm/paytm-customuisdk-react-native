# paytm-customuisdk-react-native

Paytm Custom Ui sdk plugin

## Installation

```sh
npm install paytm-customuisdk-react-native --save

react-native link paytm-customuisdk-react-native
```

## Implementation

```
Integration steps for Paytm Custom UI SDK in React Native project

Add plugins to your react-native project

npm install paytm-customuisdk-react-native --save
react-native link paytm-customuisdk-react-native
```

### Android Implementation

```
Open MainApplication.java class in android directory of react native project

import com.paytm.PaytmCustomuisdkPackage;

Then add new PaytmCustomuisdkPackage() to the list return in getPackages() method if not auto added after react-native link command in PackageList class.

@Override
       protected List<ReactPackage> getPackages() {
         @SuppressWarnings("UnnecessaryLocalVariable")
         List<ReactPackage> packages = new PackageList(this).getPackages();
         // Packages that cannot be autolinked yet can be added manually here, for example:
         packages.add(new PaytmCustomuisdkPackage());
         return packages;
       }



Append the following line to settings.gradle file.

include ':paytm-customuisdk-react-native'
project(':paytm-customuisdk-react-native').projectDir = new File(rootProject.projectDir, '../node_modules/paytm-customuisdk-react-native/android')

Add the following lines in the dependencies section of your app’s build.gradle file.

implementation project(':paytm-customuisdk-react-native');

Add below maven url in repositories of project  android/build.gradle

maven {
       url "https://artifactory.paytm.in/libs-release-local"
}

Enable multidex to use this sdk as given below in android/app/build.gradle

android {
  ...
 defaultConfig {
   ...
   multiDexEnabled true
 }
}
dependencies {
   ...
  implementation 'com.android.support:multidex:1.0.3'
}
```

### iOS Implementation

```
1: Open Podfile and Update Platform Version
      Navigate to the ios folder and open Podfile. You can do this using the following code.
   $ cd ios && open podfile.


2: Install Pods Using Cocoapods
   Install pods after updating iOS platform. : pod install && cd ..
3. Add the following in ios project.
Open the projectName.workspace in ios folder.
Open Info.plist : Add LSApplicationQueriesSchemes. Change its type to Array. Create a new item in it and set its value as "paytm"



Go to Info tab -> URL Types : Add a new URL Type that you’ll be using as the callback from Paytm App (URL Scheme: "paytm"+"MID"). Example: paytmMid123


Open AppDelegate.m: Add following method before the end of the file ended by @end
Open AppDelegate.m and Import LinkingManager to the top of the file which has delegate methods for implementing and handling URLScheme(response from Paytm invoke will be received here in this method. Which in turns notifies the Plugin.)

#import <React/RCTLinkingManager.h>

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{

  NSString *urlString = url.absoluteString;
  NSDictionary *userInfo =
  [NSDictionary dictionaryWithObject:urlString forKey:@"appInvokeNotificationKey"];
  [[NSNotificationCenter defaultCenter] postNotificationName:
   @"appInvokeNotification" object:nil userInfo:userInfo];
  return [RCTLinkingManager application:app openURL:url options:options];
}

```

## Usage

```js
import PaytmCustomuisdk, { PaytmConsentCheckBox } from 'paytm-customuisdk-react-native';


// ...

fetchAuthCode() {
   PaytmCustomuisdk.fetchAuthCode(clientId, mid)
       .then((res) => {
         setResult(JSON.stringify(res));
         setAuthCode(res.response);
       })
       .catch((err) => {
         setResult(err.message);
       });
 }

return (
          <View style={{ padding: 8 }}>
             <View>
               <PaytmConsentCheckBox
                 onChange={(e: boolean) => setAuthCheck(e)}
               />
             </View>
             <TextInput
               style={styles.textInput}
               defaultValue={clientId}
               placeholder={'Client Id'}
               onChangeText={(e) => setClientId(e)}
             />
             <View style={{ margin: 16 }}>
               <Button title="Fetch" onPress={() => fetchAuthCode()} />
             </View>
           </View>
 );

```

For more detail visit -> https://developer.paytm.com/docs/custom-ui-sdk/
