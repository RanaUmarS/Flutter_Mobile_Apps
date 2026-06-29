import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza/blocs/authentications/authentication_bloc.dart';
import 'package:pizza/home/blocs/get_pizza_bloc/get_pizza_bloc.dart';
import 'package:pizza/screens/auth/home_screen.dart';
import 'package:pizza/screens/blocs/sign_in_bloc/sign_in_bloc.dart';
import 'package:pizza/screens/views/welcome_screen.dart';
import 'package:pizza_repository/pizza_repository.dart';

class MyAppView extends StatelessWidget{
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pizza Delivery',
      theme: ThemeData(
          colorScheme: ColorScheme.light(
            background: Colors.grey.shade100,
            onBackground: Colors.black,
            primary: Colors.blue,
            onPrimary: Colors.white,
          )
      ),
      home: BlocBuilder<AuthenticationBloc, AuthenticationState>(builder: (context,state){
        if(state.status == AuthenticationStatus.authenticated){
          return MultiBlocProvider(
            providers: [BlocProvider(create: (context) => SignInBloc(
              context.read<AuthenticationBloc>().userRepository,
            ),
              ),
              BlocProvider(create: (context) => GetPizzaBloc(
                FirebasePizzaRepo()
              )..add(GetPizzas()),
              )
              ],
            child: const HomeScreen(),
          );
        }
        else{
          return WelcomeScreen();
        }
      }),
    );
  }
}