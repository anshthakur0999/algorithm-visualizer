// Algorithm data from the provided JSON
const algorithmData = {
  "sorting": [
    {
      "name": "Bubble Sort",
      "timeComplexity": {"best": "O(n)", "average": "O(n²)", "worst": "O(n²)"},
      "spaceComplexity": "O(1)",
      "description": "Simple comparison-based sorting algorithm",
      "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nvoid bubbleSort(vector<int>& arr) {\n    int n = arr.size();\n    for (int i = 0; i < n - 1; i++) {\n        for (int j = 0; j < n - i - 1; j++) {\n            if (arr[j] > arr[j + 1]) {\n                swap(arr[j], arr[j + 1]);\n            }\n        }\n    }\n}\n\nint main() {\n    vector<int> arr = {64, 34, 25, 12, 22, 11, 90};\n    bubbleSort(arr);\n    \n    for (int num : arr) {\n        cout << num << \" \";\n    }\n    return 0;\n}"
    },
    {
      "name": "Selection Sort",
      "timeComplexity": {"best": "O(n²)", "average": "O(n²)", "worst": "O(n²)"},
      "spaceComplexity": "O(1)",
      "description": "Finds minimum element and places it at the beginning",
      "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nvoid selectionSort(vector<int>& arr) {\n    int n = arr.size();\n    for (int i = 0; i < n - 1; i++) {\n        int minIdx = i;\n        for (int j = i + 1; j < n; j++) {\n            if (arr[j] < arr[minIdx]) {\n                minIdx = j;\n            }\n        }\n        swap(arr[i], arr[minIdx]);\n    }\n}\n\nint main() {\n    vector<int> arr = {64, 25, 12, 22, 11, 90};\n    selectionSort(arr);\n    \n    for (int num : arr) {\n        cout << num << \" \";\n    }\n    return 0;\n}"
    },
    {
      "name": "Merge Sort",
      "timeComplexity": {"best": "O(n log n)", "average": "O(n log n)", "worst": "O(n log n)"},
      "spaceComplexity": "O(n)",
      "description": "Divide and conquer algorithm that splits array and merges sorted halves",
      "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nvoid merge(vector<int>& arr, int left, int mid, int right) {\n    vector<int> temp(right - left + 1);\n    int i = left, j = mid + 1, k = 0;\n    \n    while (i <= mid && j <= right) {\n        if (arr[i] <= arr[j]) {\n            temp[k++] = arr[i++];\n        } else {\n            temp[k++] = arr[j++];\n        }\n    }\n    \n    while (i <= mid) temp[k++] = arr[i++];\n    while (j <= right) temp[k++] = arr[j++];\n    \n    for (i = left; i <= right; i++) {\n        arr[i] = temp[i - left];\n    }\n}\n\nvoid mergeSort(vector<int>& arr, int left, int right) {\n    if (left < right) {\n        int mid = left + (right - left) / 2;\n        mergeSort(arr, left, mid);\n        mergeSort(arr, mid + 1, right);\n        merge(arr, left, mid, right);\n    }\n}\n\nint main() {\n    vector<int> arr = {38, 27, 43, 3, 9, 82, 10};\n    mergeSort(arr, 0, arr.size() - 1);\n    \n    for (int num : arr) {\n        cout << num << \" \";\n    }\n    return 0;\n}"
    },
    {
      "name": "Quick Sort",
      "timeComplexity": {"best": "O(n log n)", "average": "O(n log n)", "worst": "O(n²)"},
      "spaceComplexity": "O(log n)",
      "description": "Efficient divide-and-conquer algorithm using pivot partitioning",
      "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nint partition(vector<int>& arr, int low, int high) {\n    int pivot = arr[high];\n    int i = (low - 1);\n    \n    for (int j = low; j <= high - 1; j++) {\n        if (arr[j] < pivot) {\n            i++;\n            swap(arr[i], arr[j]);\n        }\n    }\n    swap(arr[i + 1], arr[high]);\n    return (i + 1);\n}\n\nvoid quickSort(vector<int>& arr, int low, int high) {\n    if (low < high) {\n        int pi = partition(arr, low, high);\n        quickSort(arr, low, pi - 1);\n        quickSort(arr, pi + 1, high);\n    }\n}\n\nint main() {\n    vector<int> arr = {10, 7, 8, 9, 1, 5};\n    quickSort(arr, 0, arr.size() - 1);\n    \n    for (int num : arr) {\n        cout << num << \" \";\n    }\n    return 0;\n}"
    }
  ],
  "searching": [
    {
      "name": "Linear Search",
      "timeComplexity": {"best": "O(1)", "average": "O(n)", "worst": "O(n)"},
      "spaceComplexity": "O(1)",
      "description": "Sequential search through each element until target is found",
      "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nint linearSearch(vector<int>& arr, int target) {\n    for (int i = 0; i < arr.size(); i++) {\n        if (arr[i] == target) {\n            return i; // Return index if found\n        }\n    }\n    return -1; // Return -1 if not found\n}\n\nint main() {\n    vector<int> arr = {2, 3, 4, 10, 40};\n    int target = 10;\n    \n    int result = linearSearch(arr, target);\n    \n    if (result != -1) {\n        cout << \"Element found at index \" << result << endl;\n    } else {\n        cout << \"Element not found\" << endl;\n    }\n    \n    return 0;\n}"
    },
    {
      "name": "Binary Search",
      "timeComplexity": {"best": "O(1)", "average": "O(log n)", "worst": "O(log n)"},
      "spaceComplexity": "O(1)",
      "description": "Efficient search on sorted arrays using divide and conquer",
      "code": "#include <iostream>\n#include <vector>\nusing namespace std;\n\nint binarySearch(vector<int>& arr, int target) {\n    int left = 0, right = arr.size() - 1;\n    \n    while (left <= right) {\n        int mid = left + (right - left) / 2;\n        \n        if (arr[mid] == target) {\n            return mid;\n        }\n        \n        if (arr[mid] < target) {\n            left = mid + 1;\n        } else {\n            right = mid - 1;\n        }\n    }\n    \n    return -1; // Element not found\n}\n\nint main() {\n    vector<int> arr = {2, 3, 4, 10, 40};\n    int target = 10;\n    \n    int result = binarySearch(arr, target);\n    \n    if (result != -1) {\n        cout << \"Element found at index \" << result << endl;\n    } else {\n        cout << \"Element not found\" << endl;\n    }\n    \n    return 0;\n}"
    }
  ],
  "graph": [
    {
      "name": "Breadth-First Search",
      "timeComplexity": {"best": "O(V + E)", "average": "O(V + E)", "worst": "O(V + E)"},
      "spaceComplexity": "O(V)",
      "description": "Graph traversal algorithm that explores vertices level by level",
      "code": "#include <iostream>\n#include <vector>\n#include <queue>\nusing namespace std;\n\nclass Graph {\npublic:\n    int V; // Number of vertices\n    vector<vector<int>> adj; // Adjacency list\n    \n    Graph(int V) {\n        this->V = V;\n        adj.resize(V);\n    }\n    \n    void addEdge(int v, int w) {\n        adj[v].push_back(w);\n    }\n    \n    void BFS(int start) {\n        vector<bool> visited(V, false);\n        queue<int> queue;\n        \n        visited[start] = true;\n        queue.push(start);\n        \n        while (!queue.empty()) {\n            int v = queue.front();\n            cout << v << \" \";\n            queue.pop();\n            \n            for (int i : adj[v]) {\n                if (!visited[i]) {\n                    visited[i] = true;\n                    queue.push(i);\n                }\n            }\n        }\n    }\n};\n\nint main() {\n    Graph g(4);\n    g.addEdge(0, 1);\n    g.addEdge(0, 2);\n    g.addEdge(1, 2);\n    g.addEdge(2, 0);\n    g.addEdge(2, 3);\n    g.addEdge(3, 3);\n    \n    cout << \"BFS starting from vertex 2: \";\n    g.BFS(2);\n    \n    return 0;\n}"
    }
  ]
};

const complexityData = {
  "O(1)": {"name": "Constant", "description": "Same time regardless of input size", "points": [[1,1], [10,1], [100,1], [1000,1]]},
  "O(log n)": {"name": "Logarithmic", "description": "Time grows slowly with input size", "points": [[1,0], [10,1], [100,2], [1000,3]]},
  "O(n)": {"name": "Linear", "description": "Time grows proportionally with input size", "points": [[1,1], [10,10], [100,100], [1000,1000]]},
  "O(n log n)": {"name": "Linearithmic", "description": "Efficient divide-and-conquer algorithms", "points": [[1,0], [10,10], [100,200], [1000,3000]]},
  "O(n²)": {"name": "Quadratic", "description": "Time grows quadratically with input size", "points": [[1,1], [10,100], [100,10000], [1000,1000000]]}
};

class AlgorithmVisualizer {
  constructor() {
    this.currentAlgorithm = null;
    this.currentData = [];
    this.animationSteps = [];
    this.currentStep = 0;
    this.isPlaying = false;
    this.animationSpeed = 1000;
    this.animationTimeout = null;
    this.complexityChart = null;
    
    this.initializeElements();
    this.setupEventListeners();
    this.generateRandomArray();
  }

  initializeElements() {
    // Get all DOM elements
    this.elements = {
      algorithmTitle: document.getElementById('algorithm-title'),
      algorithmDescription: document.getElementById('algorithm-description'),
      arrayContainer: document.getElementById('array-container'),
      graphContainer: document.getElementById('graph-container'),
      codeDisplay: document.getElementById('code-display'),
      arraySizeSlider: document.getElementById('array-size'),
      arraySizeValue: document.getElementById('array-size-value'),
      customInput: document.getElementById('custom-input'),
      searchTarget: document.getElementById('search-target'),
      searchControls: document.querySelector('.search-controls'),
      generateRandomBtn: document.getElementById('generate-random'),
      applyCustomBtn: document.getElementById('apply-custom'),
      playPauseBtn: document.getElementById('play-pause-btn'),
      stepForwardBtn: document.getElementById('step-forward-btn'),
      stepBackBtn: document.getElementById('step-back-btn'),
      resetBtn: document.getElementById('reset-btn'),
      speedSlider: document.getElementById('speed-slider'),
      speedValue: document.getElementById('speed-value'),
      stepCounter: document.getElementById('step-counter'),
      statusMessage: document.getElementById('status-message'),
      timeBest: document.getElementById('time-best'),
      timeAverage: document.getElementById('time-average'),
      timeWorst: document.getElementById('time-worst'),
      spaceComplexity: document.getElementById('space-complexity'),
      complexityDescription: document.getElementById('complexity-description'),
      complexityChartCanvas: document.getElementById('complexity-chart-canvas')
    };
  }

  setupEventListeners() {
    // Algorithm selection buttons
    document.querySelectorAll('.algorithm-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const category = e.target.dataset.category;
        const algorithm = e.target.dataset.algorithm;
        this.selectAlgorithm(category, algorithm);
        
        // Update active button
        document.querySelectorAll('.algorithm-btn').forEach(b => b.classList.remove('active'));
        e.target.classList.add('active');
      });
    });

    // Array size slider
    this.elements.arraySizeSlider.addEventListener('input', (e) => {
      this.elements.arraySizeValue.textContent = e.target.value;
      this.generateRandomArray();
    });

    // Speed slider
    this.elements.speedSlider.addEventListener('input', (e) => {
      const speed = parseFloat(e.target.value);
      this.elements.speedValue.textContent = speed + 'x';
      this.animationSpeed = 1000 / speed;
    });

    // Control buttons
    this.elements.generateRandomBtn.addEventListener('click', () => this.generateRandomArray());
    this.elements.applyCustomBtn.addEventListener('click', () => this.applyCustomInput());
    this.elements.playPauseBtn.addEventListener('click', () => this.togglePlayPause());
    this.elements.stepForwardBtn.addEventListener('click', () => this.stepForward());
    this.elements.stepBackBtn.addEventListener('click', () => this.stepBack());
    this.elements.resetBtn.addEventListener('click', () => this.resetAnimation());
  }

  selectAlgorithm(category, algorithmName) {
    // Stop any current animation
    this.pause();
    
    // Find the algorithm data
    const algorithm = algorithmData[category].find(alg => alg.name === algorithmName);
    if (!algorithm) {
      console.error(`Algorithm ${algorithmName} not found in category ${category}`);
      return;
    }

    this.currentAlgorithm = { category, ...algorithm };
    
    // Update UI elements
    this.elements.algorithmTitle.textContent = algorithm.name;
    this.elements.algorithmDescription.textContent = algorithm.description;
    
    // Show/hide search controls for searching algorithms
    if (category === 'searching') {
      this.elements.searchControls.style.display = 'flex';
    } else {
      this.elements.searchControls.style.display = 'none';
    }

    // Update code display
    this.updateCodeDisplay(algorithm.code);
    
    // Update complexity information
    this.updateComplexityInfo(algorithm);
    
    // Clear previous animation steps and reset state
    this.animationSteps = [];
    this.currentStep = 0;
    this.updateStepCounter();
    this.elements.statusMessage.textContent = 'Ready to start';
    this.elements.playPauseBtn.textContent = 'Play';
    
    // Generate appropriate visualization
    if (category === 'graph') {
      this.generateGraphVisualization();
    } else {
      this.generateArrayVisualization();
    }
  }

  updateCodeDisplay(code) {
    this.elements.codeDisplay.innerHTML = `<code>${this.escapeHtml(code)}</code>`;
  }

  updateComplexityInfo(algorithm) {
    this.elements.timeBest.textContent = algorithm.timeComplexity.best;
    this.elements.timeAverage.textContent = algorithm.timeComplexity.average;
    this.elements.timeWorst.textContent = algorithm.timeComplexity.worst;
    this.elements.spaceComplexity.textContent = algorithm.spaceComplexity;
    this.elements.complexityDescription.textContent = algorithm.description;
    
    // Update complexity chart
    this.updateComplexityChart(algorithm.timeComplexity.average);
  }

  updateComplexityChart(complexity) {
    const ctx = this.elements.complexityChartCanvas.getContext('2d');
    
    if (this.complexityChart) {
      this.complexityChart.destroy();
    }

    const data = complexityData[complexity];
    if (!data) return;

    this.complexityChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.points.map(p => p[0]),
        datasets: [{
          label: `${complexity} - ${data.name}`,
          data: data.points.map(p => p[1]),
          borderColor: '#1FB8CD',
          backgroundColor: 'rgba(31, 184, 205, 0.1)',
          fill: true,
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            position: 'top'
          }
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'Input Size (n)'
            }
          },
          y: {
            title: {
              display: true,
              text: 'Time Complexity'
            }
          }
        }
      }
    });
  }

  generateRandomArray() {
    const size = parseInt(this.elements.arraySizeSlider.value);
    this.currentData = Array.from({ length: size }, () => Math.floor(Math.random() * 100) + 1);
    
    // Only regenerate visualization if we have an array-based algorithm selected
    if (this.currentAlgorithm && this.currentAlgorithm.category !== 'graph') {
      this.generateArrayVisualization();
    }
    
    // Reset animation state when data changes
    this.resetAnimationState();
  }

  applyCustomInput() {
    const input = this.elements.customInput.value.trim();
    if (!input) return;

    try {
      const values = input.split(',').map(val => parseInt(val.trim())).filter(val => !isNaN(val));
      if (values.length > 0) {
        this.currentData = values;
        this.elements.arraySizeSlider.value = values.length;
        this.elements.arraySizeValue.textContent = values.length;
        
        // Only regenerate visualization if we have an array-based algorithm selected
        if (this.currentAlgorithm && this.currentAlgorithm.category !== 'graph') {
          this.generateArrayVisualization();
        }
        
        // Reset animation state when data changes
        this.resetAnimationState();
      }
    } catch (error) {
      alert('Invalid input format. Please use comma-separated numbers.');
    }
  }

  generateArrayVisualization() {
    this.elements.arrayContainer.innerHTML = '';
    this.elements.arrayContainer.style.display = 'flex';
    this.elements.graphContainer.style.display = 'none';

    if (this.currentData.length === 0) return;

    const maxValue = Math.max(...this.currentData);
    const containerHeight = 250;

    this.currentData.forEach((value, index) => {
      const bar = document.createElement('div');
      bar.className = 'array-bar';
      bar.style.height = `${(value / maxValue) * (containerHeight - 50)}px`;
      bar.textContent = value;
      bar.dataset.index = index;
      bar.dataset.value = value;
      this.elements.arrayContainer.appendChild(bar);
    });
  }

  generateGraphVisualization() {
    this.elements.arrayContainer.style.display = 'none';
    this.elements.graphContainer.style.display = 'flex';
    this.elements.graphContainer.innerHTML = '';

    // Simple graph for BFS demonstration
    const nodes = [
      { id: 0, x: 150, y: 50 },
      { id: 1, x: 50, y: 150 },
      { id: 2, x: 250, y: 150 },
      { id: 3, x: 150, y: 250 }
    ];

    const edges = [
      { from: 0, to: 1 },
      { from: 0, to: 2 },
      { from: 1, to: 2 },
      { from: 2, to: 3 }
    ];

    // Draw edges first
    edges.forEach(edge => {
      const fromNode = nodes[edge.from];
      const toNode = nodes[edge.to];
      const edgeElement = document.createElement('div');
      edgeElement.className = 'graph-edge';
      
      const dx = toNode.x - fromNode.x;
      const dy = toNode.y - fromNode.y;
      const length = Math.sqrt(dx * dx + dy * dy);
      const angle = Math.atan2(dy, dx) * 180 / Math.PI;
      
      edgeElement.style.width = `${length}px`;
      edgeElement.style.left = `${fromNode.x}px`;
      edgeElement.style.top = `${fromNode.y}px`;
      edgeElement.style.transform = `rotate(${angle}deg)`;
      
      this.elements.graphContainer.appendChild(edgeElement);
    });

    // Draw nodes on top of edges
    nodes.forEach(node => {
      const nodeElement = document.createElement('div');
      nodeElement.className = 'graph-node';
      nodeElement.textContent = node.id;
      nodeElement.style.left = `${node.x - 20}px`;
      nodeElement.style.top = `${node.y - 20}px`;
      nodeElement.dataset.nodeId = node.id;
      this.elements.graphContainer.appendChild(nodeElement);
    });

    this.currentData = { nodes, edges };
  }

  resetAnimationState() {
    this.pause();
    this.currentStep = 0;
    this.animationSteps = [];
    this.updateStepCounter();
    this.elements.statusMessage.textContent = 'Ready to start';
    this.elements.playPauseBtn.textContent = 'Play';
  }

  resetAnimation() {
    // Reset to clean state without changing algorithm
    this.resetAnimationState();
    
    // Reset visualization to original state
    if (this.currentAlgorithm) {
      if (this.currentAlgorithm.category === 'graph') {
        this.generateGraphVisualization();
      } else {
        this.generateArrayVisualization();
      }
    }
  }

  generateAnimationSteps() {
    if (!this.currentAlgorithm) return;

    this.animationSteps = [];
    const category = this.currentAlgorithm.category;
    const name = this.currentAlgorithm.name;

    if (category === 'sorting') {
      this.generateSortingSteps(name);
    } else if (category === 'searching') {
      this.generateSearchingSteps(name);
    } else if (category === 'graph') {
      this.generateGraphSteps(name);
    }
  }

  generateSortingSteps(algorithmName) {
    const arr = [...this.currentData];
    
    switch (algorithmName) {
      case 'Bubble Sort':
        this.bubbleSortSteps(arr);
        break;
      case 'Selection Sort':
        this.selectionSortSteps(arr);
        break;
      case 'Merge Sort':
        this.mergeSortSteps(arr, 0, arr.length - 1);
        break;
      case 'Quick Sort':
        this.quickSortSteps(arr, 0, arr.length - 1);
        break;
    }
  }

  bubbleSortSteps(arr) {
    const n = arr.length;
    for (let i = 0; i < n - 1; i++) {
      for (let j = 0; j < n - i - 1; j++) {
        // Comparing elements
        this.animationSteps.push({
          type: 'compare',
          indices: [j, j + 1],
          array: [...arr],
          message: `Comparing elements at positions ${j} and ${j + 1}`
        });

        if (arr[j] > arr[j + 1]) {
          // Swap elements
          [arr[j], arr[j + 1]] = [arr[j + 1], arr[j]];
          this.animationSteps.push({
            type: 'swap',
            indices: [j, j + 1],
            array: [...arr],
            message: `Swapped elements at positions ${j} and ${j + 1}`
          });
        }
      }
      // Mark element as sorted
      this.animationSteps.push({
        type: 'sorted',
        indices: [n - i - 1],
        array: [...arr],
        message: `Element at position ${n - i - 1} is now in correct position`
      });
    }
    // Mark final element as sorted
    if (n > 0) {
      this.animationSteps.push({
        type: 'sorted',
        indices: [0],
        array: [...arr],
        message: `Sorting completed! All elements are in correct positions`
      });
    }
  }

  selectionSortSteps(arr) {
    const n = arr.length;
    for (let i = 0; i < n - 1; i++) {
      let minIdx = i;
      
      this.animationSteps.push({
        type: 'select',
        indices: [i],
        array: [...arr],
        message: `Finding minimum element from position ${i}`
      });

      for (let j = i + 1; j < n; j++) {
        this.animationSteps.push({
          type: 'compare',
          indices: [j, minIdx],
          array: [...arr],
          message: `Comparing elements at positions ${j} and ${minIdx}`
        });

        if (arr[j] < arr[minIdx]) {
          minIdx = j;
        }
      }

      if (minIdx !== i) {
        [arr[i], arr[minIdx]] = [arr[minIdx], arr[i]];
        this.animationSteps.push({
          type: 'swap',
          indices: [i, minIdx],
          array: [...arr],
          message: `Swapped minimum element to position ${i}`
        });
      }

      this.animationSteps.push({
        type: 'sorted',
        indices: [i],
        array: [...arr],
        message: `Element at position ${i} is now in correct position`
      });
    }
    // Mark final element as sorted
    if (n > 0) {
      this.animationSteps.push({
        type: 'sorted',
        indices: [n - 1],
        array: [...arr],
        message: `Sorting completed! All elements are in correct positions`
      });
    }
  }

  mergeSortSteps(arr, left, right) {
    if (left < right) {
      const mid = Math.floor((left + right) / 2);
      this.mergeSortSteps(arr, left, mid);
      this.mergeSortSteps(arr, mid + 1, right);
      this.mergeSteps(arr, left, mid, right);
    }
  }

  mergeSteps(arr, left, mid, right) {
    const temp = new Array(right - left + 1);
    let i = left, j = mid + 1, k = 0;

    while (i <= mid && j <= right) {
      this.animationSteps.push({
        type: 'compare',
        indices: [i, j],
        array: [...arr],
        message: `Comparing elements at positions ${i} and ${j}`
      });

      if (arr[i] <= arr[j]) {
        temp[k++] = arr[i++];
      } else {
        temp[k++] = arr[j++];
      }
    }

    while (i <= mid) temp[k++] = arr[i++];
    while (j <= right) temp[k++] = arr[j++];

    for (i = left; i <= right; i++) {
      arr[i] = temp[i - left];
    }

    this.animationSteps.push({
      type: 'merge',
      indices: Array.from({ length: right - left + 1 }, (_, i) => left + i),
      array: [...arr],
      message: `Merged sorted subarrays`
    });
  }

  quickSortSteps(arr, low, high) {
    if (low < high) {
      const pi = this.partitionSteps(arr, low, high);
      this.quickSortSteps(arr, low, pi - 1);
      this.quickSortSteps(arr, pi + 1, high);
    }
  }

  partitionSteps(arr, low, high) {
    const pivot = arr[high];
    let i = low - 1;

    this.animationSteps.push({
      type: 'pivot',
      indices: [high],
      array: [...arr],
      message: `Selected pivot: ${pivot} at position ${high}`
    });

    for (let j = low; j <= high - 1; j++) {
      this.animationSteps.push({
        type: 'compare',
        indices: [j, high],
        array: [...arr],
        message: `Comparing ${arr[j]} with pivot ${pivot}`
      });

      if (arr[j] < pivot) {
        i++;
        [arr[i], arr[j]] = [arr[j], arr[i]];
        this.animationSteps.push({
          type: 'swap',
          indices: [i, j],
          array: [...arr],
          message: `Swapped elements at positions ${i} and ${j}`
        });
      }
    }

    [arr[i + 1], arr[high]] = [arr[high], arr[i + 1]];
    this.animationSteps.push({
      type: 'swap',
      indices: [i + 1, high],
      array: [...arr],
      message: `Placed pivot in correct position`
    });

    return i + 1;
  }

  generateSearchingSteps(algorithmName) {
    const target = parseInt(this.elements.searchTarget.value) || 5;
    
    switch (algorithmName) {
      case 'Linear Search':
        this.linearSearchSteps(target);
        break;
      case 'Binary Search':
        // Sort array first for binary search
        const sortedArr = [...this.currentData].sort((a, b) => a - b);
        this.currentData = sortedArr;
        this.generateArrayVisualization();
        this.binarySearchSteps(target);
        break;
    }
  }

  linearSearchSteps(target) {
    for (let i = 0; i < this.currentData.length; i++) {
      this.animationSteps.push({
        type: 'search',
        indices: [i],
        array: [...this.currentData],
        message: `Checking element at position ${i}: ${this.currentData[i]}`
      });

      if (this.currentData[i] === target) {
        this.animationSteps.push({
          type: 'found',
          indices: [i],
          array: [...this.currentData],
          message: `Target ${target} found at position ${i}!`
        });
        return;
      }
    }

    this.animationSteps.push({
      type: 'not_found',
      indices: [],
      array: [...this.currentData],
      message: `Target ${target} not found in the array`
    });
  }

  binarySearchSteps(target) {
    let left = 0, right = this.currentData.length - 1;

    while (left <= right) {
      const mid = Math.floor((left + right) / 2);
      
      this.animationSteps.push({
        type: 'search',
        indices: [mid],
        array: [...this.currentData],
        message: `Checking middle element at position ${mid}: ${this.currentData[mid]}`
      });

      if (this.currentData[mid] === target) {
        this.animationSteps.push({
          type: 'found',
          indices: [mid],
          array: [...this.currentData],
          message: `Target ${target} found at position ${mid}!`
        });
        return;
      }

      if (this.currentData[mid] < target) {
        left = mid + 1;
        this.animationSteps.push({
          type: 'eliminate',
          indices: Array.from({ length: mid + 1 }, (_, i) => i),
          array: [...this.currentData],
          message: `Target is greater, searching right half`
        });
      } else {
        right = mid - 1;
        this.animationSteps.push({
          type: 'eliminate',
          indices: Array.from({ length: this.currentData.length - mid }, (_, i) => mid + i),
          array: [...this.currentData],
          message: `Target is smaller, searching left half`
        });
      }
    }

    this.animationSteps.push({
      type: 'not_found',
      indices: [],
      array: [...this.currentData],
      message: `Target ${target} not found in the array`
    });
  }

  generateGraphSteps(algorithmName) {
    if (algorithmName === 'Breadth-First Search') {
      this.bfsSteps();
    }
  }

  bfsSteps() {
    const visited = new Set();
    const queue = [0]; // Start from node 0
    visited.add(0);

    this.animationSteps.push({
      type: 'start',
      node: 0,
      message: 'Starting BFS from node 0'
    });

    while (queue.length > 0) {
      const current = queue.shift();
      
      this.animationSteps.push({
        type: 'visit',
        node: current,
        message: `Visiting node ${current}`
      });

      // Add neighbors (simplified graph structure)
      const neighbors = this.getNeighbors(current);
      for (const neighbor of neighbors) {
        if (!visited.has(neighbor)) {
          visited.add(neighbor);
          queue.push(neighbor);
          
          this.animationSteps.push({
            type: 'discover',
            node: neighbor,
            message: `Discovered node ${neighbor}, added to queue`
          });
        }
      }
    }

    this.animationSteps.push({
      type: 'complete',
      node: -1,
      message: 'BFS traversal completed!'
    });
  }

  getNeighbors(node) {
    // Simplified graph structure for demo
    const adjacencyList = {
      0: [1, 2],
      1: [0, 2],
      2: [0, 1, 3],
      3: [2]
    };
    return adjacencyList[node] || [];
  }

  togglePlayPause() {
    if (this.isPlaying) {
      this.pause();
    } else {
      this.play();
    }
  }

  play() {
    if (!this.currentAlgorithm) {
      this.elements.statusMessage.textContent = 'Please select an algorithm first';
      return;
    }
    
    if (this.animationSteps.length === 0) {
      this.generateAnimationSteps();
    }

    if (this.currentStep >= this.animationSteps.length) {
      this.elements.statusMessage.textContent = 'Animation completed. Click Reset to start over.';
      return;
    }

    this.isPlaying = true;
    this.elements.playPauseBtn.textContent = 'Pause';
    this.elements.statusMessage.textContent = 'Animation playing';
    
    this.animate();
  }

  pause() {
    this.isPlaying = false;
    this.elements.playPauseBtn.textContent = 'Play';
    
    if (this.animationTimeout) {
      clearTimeout(this.animationTimeout);
      this.animationTimeout = null;
    }
    
    if (this.currentStep < this.animationSteps.length) {
      this.elements.statusMessage.textContent = 'Animation paused';
    }
  }

  animate() {
    if (!this.isPlaying || this.currentStep >= this.animationSteps.length) {
      this.pause();
      if (this.currentStep >= this.animationSteps.length) {
        this.elements.statusMessage.textContent = 'Animation completed';
      }
      return;
    }

    this.executeStep(this.animationSteps[this.currentStep]);
    this.currentStep++;
    this.updateStepCounter();

    this.animationTimeout = setTimeout(() => {
      this.animate();
    }, this.animationSpeed);
  }

  stepForward() {
    if (!this.currentAlgorithm) {
      this.elements.statusMessage.textContent = 'Please select an algorithm first';
      return;
    }
    
    if (this.animationSteps.length === 0) {
      this.generateAnimationSteps();
    }

    if (this.currentStep < this.animationSteps.length) {
      this.executeStep(this.animationSteps[this.currentStep]);
      this.currentStep++;
      this.updateStepCounter();
      
      if (this.currentStep >= this.animationSteps.length) {
        this.elements.statusMessage.textContent = 'Animation completed';
      }
    }
  }

  stepBack() {
    if (this.currentStep > 0) {
      this.currentStep--;
      
      // Re-execute steps from beginning to current step to maintain consistency
      this.resetVisualization();
      for (let i = 0; i < this.currentStep; i++) {
        this.executeStep(this.animationSteps[i], true);
      }
      
      if (this.currentStep > 0) {
        this.elements.statusMessage.textContent = this.animationSteps[this.currentStep - 1].message;
      } else {
        this.elements.statusMessage.textContent = 'Ready to start';
      }
      
      this.updateStepCounter();
    }
  }

  resetVisualization() {
    if (!this.currentAlgorithm) return;
    
    if (this.currentAlgorithm.category === 'graph') {
      // Reset all graph nodes
      document.querySelectorAll('.graph-node').forEach(node => {
        node.className = 'graph-node';
      });
    } else {
      // Reset all array bars
      document.querySelectorAll('.array-bar').forEach(bar => {
        bar.className = 'array-bar';
      });
    }
  }

  executeStep(step, silent = false) {
    if (this.currentAlgorithm.category === 'graph') {
      this.executeGraphStep(step);
    } else {
      this.executeArrayStep(step);
    }
    
    if (!silent) {
      this.elements.statusMessage.textContent = step.message;
    }
  }

  executeArrayStep(step) {
    // Reset all bars first
    document.querySelectorAll('.array-bar').forEach(bar => {
      bar.className = 'array-bar';
    });

    // Update array values if provided
    if (step.array) {
      const bars = document.querySelectorAll('.array-bar');
      step.array.forEach((value, index) => {
        if (bars[index]) {
          bars[index].textContent = value;
          bars[index].dataset.value = value;
          
          const maxValue = Math.max(...step.array);
          const containerHeight = 250;
          bars[index].style.height = `${(value / maxValue) * (containerHeight - 50)}px`;
        }
      });
    }

    // Apply step-specific styling
    if (step.indices) {
      step.indices.forEach(index => {
        const bar = document.querySelector(`[data-index="${index}"]`);
        if (bar) {
          switch (step.type) {
            case 'compare':
              bar.classList.add('comparing');
              break;
            case 'swap':
            case 'active':
            case 'pivot':
              bar.classList.add('active');
              break;
            case 'sorted':
            case 'merge':
              bar.classList.add('sorted');
              break;
            case 'search':
              bar.classList.add('searching');
              break;
            case 'found':
              bar.classList.add('found');
              break;
            case 'select':
              bar.classList.add('active');
              break;
          }
        }
      });
    }
  }

  executeGraphStep(step) {
    // Apply step-specific styling
    const node = document.querySelector(`[data-node-id="${step.node}"]`);
    if (node) {
      switch (step.type) {
        case 'start':
        case 'visit':
          node.classList.add('current');
          break;
        case 'discover':
          node.classList.add('visited');
          break;
      }
    }
  }

  updateStepCounter() {
    this.elements.stepCounter.textContent = `Step: ${this.currentStep} / ${this.animationSteps.length}`;
  }

  escapeHtml(text) {
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
  }
}

// Initialize the application
document.addEventListener('DOMContentLoaded', () => {
  new AlgorithmVisualizer();
});