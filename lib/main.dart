import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_state.dart';
import 'firebase_options.dart';

AppOpenAd? myAppOpenAd;


loadAppOpenAd() {
  AppOpenAd.load(
      adUnitId: "ca-app-pub-3940256099942544/9257395921", //Your ad Id from admob
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            myAppOpenAd = ad;
            myAppOpenAd!.show();
          },
          onAdFailedToLoad: (error) {}),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  
);
  await FirebaseAnalytics.instance.logAppOpen();
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  MobileAds.instance.initialize();
   loadAppOpenAd();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return MyHomePage(title: 'Flutter Demo Home Page');
        }

        return const SignInPage();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  int _counter = 0;
  late BannerAd _bannerAd;
  bool _isloaded = false;
  late InterstitialAd _interstitialAd;
  bool _interstitialAdLoaded =false;


  void initAD(){
    InterstitialAd.load(
      adUnitId: "ca-app-pub-3940256099942544/1033173712",
       request: AdRequest(), 
       adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (error){
          print(error);
        }));
  }
  @override

  void initState(){
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isloaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          print('Ad failed to load: $error');
        },
      ),
    );
    _bannerAd.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 34,),
            ElevatedButton(onPressed: signout, child: Text('Signout')),
            ElevatedButton(onPressed: DeleteUser, child: Text('Delete Account')),
            ElevatedButton(
              onPressed: _incrementCounter,
              
              child: const Icon(Icons.add),
            ),
            ElevatedButton(onPressed: (){
              if(_interstitialAdLoaded){
                _interstitialAd.show();
              }else{
                print("Ad not loaded");
              }
            }, child: Text("Interstial Add")),
            
          ],
        ),
      ),
      bottomNavigationBar: _isloaded?Container(
        height: _bannerAd.size.height.toDouble(),
        width: _bannerAd.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd),
      ):null,
      floatingActionButton: null,
    );
  }

  void _incrementCounter() async {
  try {
    await FirebaseAnalytics.instance.logEvent(
      name: 'plus_button_clicked',
      parameters: {
        'counter_value': _counter.toString(),
      },
      
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('succesfuly logged'),
          content: const Text('Logged'),
        );
      },
    );
    setState(() {
      _counter++;
    });
  } catch (error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(error.toString()),
        );
      },
    );
  }
}
  Future signout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future DeleteUser() async {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed with error code: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void onAdLoaded(InterstitialAd ad) {
    setState(() {
      _interstitialAd = ad;
      _interstitialAdLoaded = true;
      _interstitialAd.fullScreenContentCallback=FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad){
          _interstitialAd.dispose();

        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _interstitialAd.dispose();
          
        },
        
      );
    });
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Email'),
                controller: emailController,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );
                  } catch (e) {
                    print('Sign in failed: $e');
                    // Handle sign in errors
                  }
                },
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signInAnonymously(
                     
                    );
                  } catch (e) {
                    print('Sign in failed: $e');
                    // Handle sign in errors
                  }
                },
                child: const Text('Sign In Anonumously'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgetPage()));
                },
                child: const Text('Forget Password'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
      
    );
    
  }}
  
class SignUpPage extends StatelessWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Email'),
                controller: emailController,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );
                  } catch (e) {
                    print('Sign up failed: $e');
                    // Handle sign up errors
                  }
                },
                child: const Text('Sign Up'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInPage()));
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgetPage extends StatelessWidget {
  const ForgetPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forget Password'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Email'),
                controller: emailController,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Password Reset'),
                          content: const Text('An email with instructions to reset your password has been sent.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  } catch (e) {
                    print('Password reset failed: $e');
                    // Handle password reset errors
                  }
                },
                child: const Text('Reset Password'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInPage()));
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),

      
    );
  }
}