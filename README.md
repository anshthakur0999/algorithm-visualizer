# DSA Algorithm Visualizer

An interactive web-based tool for visualizing Data Structures and Algorithms (DSA) with C++ implementations. This educational platform helps students and developers understand how various algorithms work through step-by-step visual animations.

🚀 **[Live Demo](https://algorithm-visualizer-xi-nine.vercel.app)**

![DSA Algorithm Visualizer](https://img.shields.io/badge/Status-Active-brightgreen)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?logo=javascript&logoColor=black)
![C++](https://img.shields.io/badge/C++-00599C?logo=c%2B%2B&logoColor=white)

## 🚀 Features

### 📊 Algorithm Categories
- **Sorting Algorithms**: Bubble Sort, Selection Sort, Merge Sort, Quick Sort
- **Searching Algorithms**: Linear Search, Binary Search
- **Graph Algorithms**: Breadth-First Search (BFS)

### 🎯 Interactive Visualizations
- **Step-by-step animations** with customizable speed control
- **Real-time array/graph state visualization** with color-coded elements
- **Manual step control** (play, pause, step forward/backward, reset)
- **Custom input support** for testing with your own data
- **Responsive design** that works on desktop and mobile devices

### 💻 Educational Features
- **Complete C++ implementations** for each algorithm
- **Time and space complexity analysis** with visual charts
- **Detailed explanations** of each algorithm's behavior
- **Interactive controls** for array size and custom values
- **Search target specification** for searching algorithms

### 🎨 User Interface
- **Clean, modern design** with intuitive navigation
- **Sidebar navigation** for easy algorithm selection
- **Real-time complexity visualization** using Chart.js
- **Status messages** explaining each step of the algorithm
- **Responsive layout** optimized for learning

## 🛠️ Technologies Used

- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Visualization**: Custom CSS animations and Chart.js
- **Styling**: Modern CSS with CSS Grid and Flexbox
- **Code Display**: Syntax highlighting for C++ code

## 🚀 Getting Started

### Prerequisites
- A modern web browser (Chrome, Firefox, Safari, Edge)
- No additional installations required!

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/anshthakur0999/algorithm-visualizer.git
   cd algorithm-visualizer
   ```

2. **Open the application**
   ```bash
   # Simply open index.html in your web browser
   open index.html
   # or
   double-click index.html
   ```

3. **For local development server (optional)**
   ```bash
   # Using Python
   python -m http.server 8000
   # or using Node.js
   npx serve .
   ```

## 📖 How to Use

1. **Select an Algorithm**: Choose from the sidebar categories (Sorting, Searching, Graph)
2. **Configure Input**: 
   - Adjust array size using the slider
   - Enter custom values in the input field
   - Set search target for searching algorithms
3. **Control Animation**:
   - Click "Play" to start automatic animation
   - Use "Step Forward/Back" for manual control
   - Adjust speed with the speed slider
   - "Reset" to return to initial state
4. **Learn**: 
   - View the C++ implementation
   - Analyze time/space complexity
   - Read step-by-step explanations

## 🎯 Supported Algorithms

### Sorting Algorithms
| Algorithm | Best Case | Average Case | Worst Case | Space Complexity |
|-----------|-----------|--------------|------------|------------------|
| Bubble Sort | O(n) | O(n²) | O(n²) | O(1) |
| Selection Sort | O(n²) | O(n²) | O(n²) | O(1) |
| Merge Sort | O(n log n) | O(n log n) | O(n log n) | O(n) |
| Quick Sort | O(n log n) | O(n log n) | O(n²) | O(log n) |

### Searching Algorithms
| Algorithm | Best Case | Average Case | Worst Case | Space Complexity |
|-----------|-----------|--------------|------------|------------------|
| Linear Search | O(1) | O(n) | O(n) | O(1) |
| Binary Search | O(1) | O(log n) | O(log n) | O(1) |

### Graph Algorithms
| Algorithm | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| Breadth-First Search | O(V + E) | O(V) |

## 🎨 Customization

### Adding New Algorithms
1. Add algorithm data to `algorithmData` object in `app.js`
2. Implement the step generation function
3. Add visualization logic for the new algorithm type
4. Update the HTML sidebar with the new algorithm button

### Styling
- Modify `style.css` to change colors, fonts, and layout
- CSS custom properties (variables) are defined in `:root` for easy theming
- Responsive breakpoints can be adjusted for different screen sizes

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

### Ideas for Contributions
- Add more sorting algorithms (Heap Sort, Radix Sort, etc.)
- Implement additional graph algorithms (DFS, Dijkstra's, etc.)
- Add tree data structure visualizations
- Improve mobile responsiveness
- Add algorithm performance comparisons
- Implement dark/light theme toggle

## 🙏 Acknowledgments

- Inspired by various algorithm visualization tools
- Built for educational purposes to help students learn DSA concepts
- C++ implementations follow standard algorithmic approaches
- Chart.js for complexity visualization graphs

## 📞 Contact

- **GitHub**: [@anshthakur0999](https://github.com/anshthakur0999)
- **Email**: anshthakur0999@gmail.com

---

⭐ **Star this repository if you found it helpful!**

Made with ❤️ for the programming community
