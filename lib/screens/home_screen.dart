import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/screens/paint_detail_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    PaintListTab(),
    SearchTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar:
          _selectedIndex == 0
              ? AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hi Angelo,'),
                    Text(
                      'You have 5 paints pending this week',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    tooltip: 'Toggle theme',
                    onPressed: () {
                      final newTheme =
                          isDarkMode
                              ? ThemeProvider.LIGHT_THEME
                              : ThemeProvider.DARK_THEME;
                      themeProvider.setThemeMode(newTheme);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://randomuser.me/api/portraits/men/1.jpg',
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              )
              : AppBar(
                title: Text(_selectedIndex == 1 ? 'Search' : 'Profile'),
                actions: [
                  IconButton(
                    icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    tooltip: 'Toggle theme',
                    onPressed: () {
                      final newTheme =
                          isDarkMode
                              ? ThemeProvider.LIGHT_THEME
                              : ThemeProvider.DARK_THEME;
                      themeProvider.setThemeMode(newTheme);
                    },
                  ),
                ],
              ),
      body: _screens.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkSurface
                  : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class PaintListTab extends StatelessWidget {
  const PaintListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final paints = SampleData.getPaints();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de puntos (similar a la tarjeta azul en la imagen)
            Card(
              color: AppTheme.primaryBlue,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${paints.length * 30} Points',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Great job! Keep adding paints to your collection.',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                      child: const Text('Add new paint'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sección de Pendientes (como las tarjetas Law of Motion en la imagen)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Paints',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(onPressed: () {}, child: const Text('See all')),
              ],
            ),

            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final paint = paints[index];
                return PaintGridCard(
                  paint: paint,
                  color: AppTheme.getCategoryColor(index),
                );
              },
            ),

            const SizedBox(height: 24),

            // Sección de Categorías (como los botones de Subjects en la imagen)
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                CategoryCard(
                  title: 'Citadel',
                  count: 7,
                  color: AppTheme.primaryBlue,
                  onTap: () {},
                ),
                CategoryCard(
                  title: 'Vallejo',
                  count: 3,
                  color: AppTheme.pinkColor,
                  onTap: () {},
                ),
                CategoryCard(
                  title: 'Army Painter',
                  count: 0,
                  color: AppTheme.purpleColor,
                  onTap: () {},
                ),
                CategoryCard(
                  title: 'Scale75',
                  count: 0,
                  color: AppTheme.orangeColor,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Lista de todas las pinturas
            Text('All Paints', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paints.length,
              itemBuilder: (context, index) {
                final paint = paints[index];
                return PaintCard(paint: paint);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PaintGridCard extends StatelessWidget {
  final Paint paint;
  final Color color;

  const PaintGridCard({super.key, required this.paint, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaintDetailScreen(paint: paint),
          ),
        );
      },
      child: Card(
        color: color.withOpacity(0.1),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paint.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(paint.brand, style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(paint.colorHex.substring(1, 7), radix: 16) +
                            0xFF000000,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    paint.category,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PaintCard extends StatelessWidget {
  final Paint paint;

  const PaintCard({super.key, required this.paint});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaintDetailScreen(paint: paint),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(paint.colorHex.substring(1, 7), radix: 16) +
                        0xFF000000,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paint.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          paint.brand,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            paint.category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (paint.isMetallic)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Metallic',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Paints by Color',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Enter color name or hex code',
              prefixIcon: Icon(Icons.color_lens),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Or take a photo to match',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Camera functionality would go here
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Popular Colors',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ColorChip(color: Colors.red[900]!, label: 'Red'),
              ColorChip(color: Colors.blue[800]!, label: 'Blue'),
              ColorChip(color: Colors.green[700]!, label: 'Green'),
              ColorChip(color: Colors.amber[600]!, label: 'Yellow'),
              ColorChip(color: Colors.purple[500]!, label: 'Purple'),
              ColorChip(color: Colors.black, label: 'Black'),
              ColorChip(color: Colors.white, label: 'White'),
              ColorChip(color: Colors.grey, label: 'Grey'),
            ],
          ),
        ],
      ),
    );
  }
}

class ColorChip extends StatelessWidget {
  final Color color;
  final String label;

  const ColorChip({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 12),
      label: Text(label),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          const Text(
            'User Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ProfileMenuItem(
            icon: Icons.collections,
            title: 'My Collection',
            onTap: () {
              // Navigate to collection screen
            },
          ),
          ProfileMenuItem(
            icon: Icons.favorite,
            title: 'Favorites',
            onTap: () {
              // Navigate to favorites screen
            },
          ),
          ProfileMenuItem(
            icon: Icons.history,
            title: 'Recent Searches',
            onTap: () {
              // Navigate to recent searches
            },
          ),
          ProfileMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              // Navigate to settings screen
            },
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Theme Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: const Text('System Theme'),
                  value: ThemeProvider.SYSTEM_THEME,
                  groupValue: themeProvider.themePreference,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Light Theme'),
                  value: ThemeProvider.LIGHT_THEME,
                  groupValue: themeProvider.themePreference,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Dark Theme'),
                  value: ThemeProvider.DARK_THEME,
                  groupValue: themeProvider.themePreference,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              // Login functionality will be added later
            },
            icon: const Icon(Icons.login),
            label: const Text('Sign In'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
