import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =================== MODELO Y ALMACENAMIENTO DE JUEGOS ===================
class Game {
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  Game({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      name: json['name'],
      price: json['price'],
      imageUrl: json['imageUrl'],
      description: json['description'],
    );
  }
}

class GameStorage {
  static SharedPreferences? _prefs;
  static const String gamesKey = 'games';

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (!_prefs!.containsKey(gamesKey)) {
      await _prefs!.setString(gamesKey, jsonEncode([]));
    }
  }

  static List<Game> loadGames() {
    String jsonString = _prefs!.getString(gamesKey)!;
    List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((item) => Game.fromJson(item)).toList();
  }

  static Future<void> saveGames(List<Game> games) async {
    String jsonString = jsonEncode(games.map((game) => game.toJson()).toList());
    await _prefs!.setString(gamesKey, jsonString);
  }

  static Future<void> addGame(Game game) async {
    List<Game> games = loadGames();
    games.add(game);
    await saveGames(games);
  }

  static Future<void> updateGame(int index, Game game) async {
    List<Game> games = loadGames();
    if (index >= 0 && index < games.length) {
      games[index] = game;
      await saveGames(games);
    }
  }
}

// =================== MODELO Y ALMACENAMIENTO DE USUARIOS ===================
class AppUser {
  String email;
  String name;
  String password;

  AppUser({
    required this.email,
    required this.name,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'password': password,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      email: json['email'],
      name: json['name'],
      password: json['password'],
    );
  }
}

class UserStorage {
  static SharedPreferences? _prefs;
  static const String usersKey = 'users';

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (!_prefs!.containsKey(usersKey)) {
      await _prefs!.setString(usersKey, jsonEncode([]));
    }
  }

  static List<AppUser> loadUsers() {
    String jsonString = _prefs!.getString(usersKey)!;
    List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((item) => AppUser.fromJson(item)).toList();
  }

  static Future<void> saveUsers(List<AppUser> users) async {
    String jsonString = jsonEncode(users.map((user) => user.toJson()).toList());
    await _prefs!.setString(usersKey, jsonString);
  }

  static Future<void> addUser(AppUser user) async {
    List<AppUser> users = loadUsers();
    users.add(user);
    await saveUsers(users);
  }

  static Future<void> updateUser(String email, AppUser updatedUser) async {
    List<AppUser> users = loadUsers();
    int index = users.indexWhere((user) => user.email == email);
    if (index != -1) {
      users[index] = updatedUser;
      await saveUsers(users);
    }
  }
}

// =================== SESIÓN, CARRITO Y JUEGOS ADQUIRIDOS ===================
class UserSession {
  static bool isAdmin = false;
  static AppUser? currentUser;
}

List<Game> cartItems = [];
List<Game> purchasedGames = [];

// =================== WIDGET PERSONALIZADO: GRID ITEM ===================
class GameGridItem extends StatefulWidget {
  final Game game;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  const GameGridItem({
    Key? key,
    required this.game,
    required this.index,
    this.onTap,
    this.onEdit,
  }) : super(key: key);

  @override
  _GameGridItemState createState() => _GameGridItemState();
}

class _GameGridItemState extends State<GameGridItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Card(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Imagen de fondo
              Positioned.fill(
                child: Image.network(
                  widget.game.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // Overlay de descripción al hover
              if (isHovered)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(4),
                  child: Text(
                    widget.game.description,
                    style: TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Datos en la parte inferior
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.game.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10),
                        textAlign: TextAlign.center),
                    Text('\$${widget.game.price.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.green, fontSize: 9),
                        textAlign: TextAlign.center),
                    if (UserSession.isAdmin && widget.onEdit != null)
                      IconButton(
                        icon: Icon(Icons.edit, size: 12),
                        onPressed: widget.onEdit,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== MAIN ===================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameStorage.initialize();
  await UserStorage.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3 DS Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/addGame': (context) => AddGamePage(),
        '/cart': (context) => CartPage(),
        '/friends': (context) => FriendsPage(),
        '/profile': (context) => ProfilePage(),
        '/editProfile': (context) => EditProfilePage(),
      },
    );
  }
}

// =================== DRAWER DE NAVEGACIÓN ===================
class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey[850]),
              child: Center(
                  child: Text('3 DS Store',
                      style: TextStyle(fontSize: 24, color: Colors.white)))),
          ListTile(
            leading: Icon(Icons.store),
            title: Text('3 DS Store'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Perfil'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Amigos'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/friends');
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Carrito'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/cart');
            },
          ),
          if (UserSession.currentUser == null)
            ListTile(
              leading: Icon(Icons.login),
              title: Text('Login'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
        ],
      ),
    );
  }
}

// =================== PÁGINA PRINCIPAL: 3 DS STORE ===================
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Game> games = [];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  void _loadGames() {
    setState(() {
      games = GameStorage.loadGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        centerTitle: true,
        title: Text('3 DS Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
          if (UserSession.isAdmin)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, '/addGame')
                    .then((_) => _loadGames());
              },
            ),
        ],
      ),
      body: games.isEmpty
          ? Center(child: Text('No hay juegos en el catálogo.'))
          : Padding(
              padding: const EdgeInsets.all(4.0),
              child: GridView.builder(
                itemCount: games.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, // Cuadros aún más pequeños
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.55,
                ),
                itemBuilder: (context, index) {
                  Game game = games[index];
                  return GameGridItem(
                    game: game,
                    index: index,
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      GameDetailPage(game: game, index: index)))
                          .then((_) => _loadGames());
                    },
                    onEdit: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EditGamePage(game: game, index: index)));
                    },
                  );
                },
              ),
            ),
    );
  }
}

// =================== PÁGINA DE DETALLE DEL JUEGO ===================
class GameDetailPage extends StatelessWidget {
  final Game game;
  final int index;
  const GameDetailPage({Key? key, required this.game, required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(game.name),
        actions: [
          if (UserSession.isAdmin)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditGamePage(game: game, index: index)));
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(game.imageUrl,
                width: double.infinity, height: 250, fit: BoxFit.cover),
            SizedBox(height: 10),
            Text(game.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('\$${game.price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, color: Colors.green)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(game.description, style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                if (UserSession.currentUser != null) {
                  cartItems.add(game);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${game.name} agregado al carrito')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Inicia sesión para comprar')));
                }
              },
              child: Text('Agregar al carrito'),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== PÁGINA PARA EDITAR JUEGO (Solo Admin) ===================
class EditGamePage extends StatefulWidget {
  final Game game;
  final int index;
  const EditGamePage({Key? key, required this.game, required this.index})
      : super(key: key);

  @override
  _EditGamePageState createState() => _EditGamePageState();
}

class _EditGamePageState extends State<EditGamePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController imageUrlController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.game.name);
    priceController = TextEditingController(text: widget.game.price.toString());
    imageUrlController = TextEditingController(text: widget.game.imageUrl);
    descriptionController =
        TextEditingController(text: widget.game.description);
  }

  void _saveEdits() async {
    if (_formKey.currentState!.validate()) {
      String name = nameController.text;
      double price = double.tryParse(priceController.text) ?? 0.0;
      String imageUrl = imageUrlController.text;
      String description = descriptionController.text;
      Game updatedGame = Game(
          name: name,
          price: price,
          imageUrl: imageUrl,
          description: description);
      await GameStorage.updateGame(widget.index, updatedGame);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${widget.game.name}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nombre del juego'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: imageUrlController,
                decoration: InputDecoration(labelText: 'URL de la imagen'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Descripción'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEdits,
                child: Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== PÁGINA PARA AGREGAR JUEGOS (Solo Admin) ===================
class AddGamePage extends StatefulWidget {
  @override
  _AddGamePageState createState() => _AddGamePageState();
}

class _AddGamePageState extends State<AddGamePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void _saveGame() async {
    if (_formKey.currentState!.validate()) {
      String name = nameController.text;
      double price = double.tryParse(priceController.text) ?? 0.0;
      String imageUrl = imageUrlController.text;
      String description = descriptionController.text;
      Game newGame = Game(
          name: name,
          price: price,
          imageUrl: imageUrl,
          description: description);
      await GameStorage.addGame(newGame);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!UserSession.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text('Agregar Juego')),
        body: Center(child: Text('Acceso no autorizado')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Juego'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nombre del juego'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: imageUrlController,
                decoration: InputDecoration(labelText: 'URL de la imagen'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Descripción'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveGame,
                child: Text('Guardar Juego'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== PÁGINA DE LOGIN ===================
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  void _login() {
    String username = userController.text;
    String password = passwordController.text;

    // Modo admin
    if (username == 'Admin' && password == 'Admin') {
      UserSession.isAdmin = true;
      UserSession.currentUser =
          AppUser(email: 'admin@admin.com', name: 'Admin', password: 'Admin');
      Navigator.pop(context);
      return;
    }
    // Validación contra usuarios registrados
    List<AppUser> users = UserStorage.loadUsers();
    AppUser? foundUser;
    for (var user in users) {
      if (user.email == username && user.password == password) {
        foundUser = user;
        break;
      }
    }
    if (foundUser != null) {
      UserSession.isAdmin = false;
      UserSession.currentUser = foundUser;
      Navigator.pop(context);
    } else {
      setState(() {
        errorMessage = 'Credenciales incorrectas';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: userController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Correo o Usuario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _login,
                    icon: Icon(Icons.login),
                    label: Text('Login'),
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(errorMessage,
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =================== PÁGINA DE REGISTRO ===================
class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  void _register() async {
    if (_formKey.currentState!.validate()) {
      String email = emailController.text;
      String name = nameController.text;
      String password = passwordController.text;

      List<AppUser> users = UserStorage.loadUsers();
      bool exists = users.any((user) => user.email == email);
      if (exists) {
        setState(() {
          errorMessage = 'El usuario ya existe';
        });
        return;
      }

      AppUser newUser = AppUser(email: email, name: name, password: password);
      await UserStorage.addUser(newUser);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro de Usuario')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                        labelText: 'Correo', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                        labelText: 'Nombre', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                        labelText: 'Contraseña', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _register,
                    child: Text('Registrar'),
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(errorMessage,
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =================== PÁGINA DEL CARRITO ===================
class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<bool> selected = [];

  @override
  void initState() {
    super.initState();
    selected = List<bool>.filled(cartItems.length, false);
  }

  double get total {
    double subtotal = 0.0;
    for (int i = 0; i < cartItems.length; i++) {
      if (selected.length > i && selected[i]) {
        subtotal += cartItems[i].price;
      }
    }
    return subtotal * 1.1; // 10% impuestos
  }

  @override
  Widget build(BuildContext context) {
    // Actualiza la lista de selección si el carrito cambia
    if (selected.length != cartItems.length) {
      selected = List<bool>.filled(cartItems.length, false);
    }
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Carrito de Compras'),
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? Center(child: Text('El carrito está vacío.'))
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      Game game = cartItems[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: Image.network(game.imageUrl,
                              width: 50, height: 50, fit: BoxFit.cover),
                          title: Text(game.name),
                          subtitle: Text('\$${game.price.toStringAsFixed(2)}'),
                          trailing: Checkbox(
                            value: selected[index],
                            onChanged: (bool? value) {
                              setState(() {
                                selected[index] = value ?? false;
                              });
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GameDetailPage(
                                        game: game, index: index)));
                          },
                        ),
                      );
                    },
                  ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Total (con impuestos): \$${total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (UserSession.currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Inicia sesión para comprar')));
                      return;
                    }
                    // Simula la compra: añade los juegos seleccionados a los adquiridos
                    for (int i = 0; i < cartItems.length; i++) {
                      if (selected[i]) {
                        purchasedGames.add(cartItems[i]);
                      }
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Compra realizada por \$${total.toStringAsFixed(2)}')));
                    setState(() {
                      cartItems.clear();
                      selected.clear();
                    });
                  },
                  child: Text('Comprar Ahora'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =================== PÁGINA DE AMIGOS ===================
class FriendsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Amigos'),
      ),
      body: Center(
        child: Text('Sección de amigos (pendiente de implementación)',
            style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

// =================== PÁGINA DE PERFIL ===================
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Para usuarios normales, se muestran los juegos adquiridos en orden alfabético;
    // Si es admin se muestran todos los juegos.
    List<Game> displayGames;
    if (UserSession.isAdmin) {
      displayGames = GameStorage.loadGames();
    } else {
      displayGames = List.from(purchasedGames);
      displayGames.sort((a, b) => a.name.compareTo(b.name));
    }
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Perfil'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/editProfile');
            },
          )
        ],
      ),
      body: displayGames.isEmpty
          ? Center(child: Text('No has adquirido juegos aún.'))
          : ListView.builder(
              itemCount: displayGames.length,
              itemBuilder: (context, index) {
                Game game = displayGames[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Image.network(game.imageUrl,
                        width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(game.name),
                    subtitle: Text('\$${game.price.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
    );
  }
}

// =================== PÁGINA DE EDICIÓN DEL PERFIL ===================
class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController nameController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    if (UserSession.currentUser != null) {
      emailController =
          TextEditingController(text: UserSession.currentUser!.email);
      nameController =
          TextEditingController(text: UserSession.currentUser!.name);
      passwordController =
          TextEditingController(text: UserSession.currentUser!.password);
    } else {
      emailController = TextEditingController();
      nameController = TextEditingController();
      passwordController = TextEditingController();
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate() && UserSession.currentUser != null) {
      AppUser updatedUser = AppUser(
          email: emailController.text,
          name: nameController.text,
          password: passwordController.text);
      await UserStorage.updateUser(UserSession.currentUser!.email, updatedUser);
      UserSession.currentUser = updatedUser;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Correo'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
