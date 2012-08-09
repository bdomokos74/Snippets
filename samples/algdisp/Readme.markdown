AlgDisp
=======

AlgDisp tool is a small app for visualizing graph algoritms' working for educational purposes, 
inspired by https://www.ai-class.com

The result of this tool is in html format, and looks like this:
https://github.com/bdomokos74/AlgDisp/wiki

Install
=======

Requirements:

* ruby
* graphviz - tool for drawing graphs
* ruby-graphviz - graphviz gem for ruby
* launchy - gem for opening an html in the browser

Steps to install:

1. Install graphviz from http://www.graphviz.org
2. gem install ruby-graphviz
3. gem install launchy
4. git clone https://github.com/bdomokos74/AlgDisp

Run
===

To run on the example input graph (map1.gv): 

	ruby run_alg.rb

The result.html is generated in the output/ directory, something like this:
https://github.com/bdomokos74/AlgDisp/wiki

Modify
======

To change the graph, edit map1.gv. To change the algorithm, edit run_alg.rb.

References
==========

https://www.ai-class.com/course/video/quizquestion/20

Todo
====

* Add parameters for choosing algs
* Add more algs
