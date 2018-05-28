# Overview Weaver.Model

## 1. Intro
`Weaver.Model` is a concept that only exists SDK (client) side. It is a filtered way to interact with the *schemaless* graph data inside a Weaver Project.
- If it is used to create data it will function like a schema by validating the input.
- If used for reading it will show these nodes, attributes and relations the model describes.

### Definition

A model is defined in a `.yml` file:
```yaml
name: some-model
version: 1.0.0

classes:
  Thing
```

Which can be visualised in a UML-like diagram:
```graphviz
digraph {
  rankdir=LR;
  subgraph cluster_0 {
    label="some-model";
    rankdir=LR;
    node [shape = ellipse];
    Thing
  }
}
```

![Alt text](https://g.gravizo.com/source/custom_mark10?https%3A%2F%2Fraw.githubusercontent.com%2Fweaverplatform%2Fweaver-sdk-js%2Fmodel-ideas%2Fmodels.md)
<details> 
<summary></summary>
custom_mark10
	digraph {
		rankdir=LR;
		subgraph cluster_0 {
			label="some-model";
			rankdir=LR;
			node [shape = ellipse];
			Thing
		}
	}
custom_mark10
</details>

```
![Alt text](https://g.gravizo.com/source/custom_mark10?https%3A%2F%2Fraw.githubusercontent.com%2Fweaverplatform%2Fweaver-sdk-js%2Fmodel-ideas%2Fmodels.md)
<details> 
<summary></summary>
custom_mark10
	digraph {
		rankdir=LR;
		subgraph cluster_0 {
			label="some-model";
			rankdir=LR;
			node [shape = ellipse];
			Thing
		}
	}
custom_mark10
</details>
```



### Concepts

Concepts in the model are `classes`, `relations` and `attributes`. 
```yaml
name: some-model
version: 1.0.0

classes:
  Thing:
  Person:
    attributes:
      name:
        datatype: string
    relations:
      owns:
        range: Thing
```

```graphviz
digraph {
  rankdir=LR;
  subgraph cluster_0 {
    label="some-model";
    rankdir=LR;
    node [shape = ellipse];
    Person
    Thing
    name [label="_string_"; shape = box]
    Person -> name [label=name; arrowtail=diamond; arrowhead=vee; dir=both];
    Person -> Thing [label=owns; arrowtail=diamond; arrowhead=vee; dir=both];
  }
}
```

### Punning

Relations can also be references as classes.
```yaml
name: some-model
version: 1.0.0

classes:
  Thing:
  Person:
    attributes:
      name:
        datatype: string
    relations:
      owns:
        range: Thing
  owns:
    attributes:
      since: 
        datatype: datetime
```

```graphviz
digraph {
  rankdir=LR;
  subgraph cluster_0 {
    label="some-model";
    rankdir=LR;
    node [shape = ellipse];
    Person
    Thing
    name [label="_string_"; shape = box]
    since [label="_datetime_"; shape = box]
    owns [label="owns"; shape = diamond]
    Person -> name [label=name; arrowtail=diamond; arrowhead=vee; dir=both];
    Person -> owns [label=""; arrowtail=diamond; arrowhead=none; dir=both];
    owns -> Thing [label=""; arrowhead=vee];
    owns -> since [label=since; arrowtail=diamond; arrowhead=vee; dir=both];

    {rank=same owns name since}
    since -> owns  [style="invis"]


  }
}
```

## 2. Inclusion and inheritence
```graphviz
digraph {
  rankdir=LR;
  subgraph cluster_0 {
    label="fruit-model";
    rankdir=LR;
    node [shape = diamond];
    eaterOwns [label="owns"];
    node [shape = box];
    Eater -> Fruit [label=eats; arrowtail=diamond; arrowhead=vee; dir=both];
    Fruit -> Color [label=hasColor; arrowtail=diamond; arrowhead=vee; dir=both];
    Eater -> eaterOwns [label=""; arrowtail=diamond; arrowhead=none; dir=both];
    eaterOwns -> Fruit [label=owns; arrowhead=vee];
    eaterOwns -> Date [label=since; arrowtail=diamond; arrowhead=vee; dir=both];
  }
}
```

```yaml
name: fruit-model
version: 1.0.0

classes:
  Fruit:                       # fruit-model:Fruit
    relations:
      hasColor:
        range: Color
  Eater:                       # fruit-model:Eater
    relations:
      owns:                    # fruit-model:owns
        range: Fruit 
      eats:                    # fruit-model:eats
        range: Fruit 

  owns:                        # fruit-model:owns
    relations:
      since:                   # fruit-model:since
        range: Date 
  
  Date:                        # fruit-model:Date
  Color:                       # fruit-model:Color
```


Inherit from included model:
```graphviz
digraph {
  rankdir=LR;
  subgraph cluster_0 {
    label="fruit-model";
    eaterOwns [shape = diamond; label="owns"];
    node [shape = box];
    Eater; Fruit; Color; Fruit; Date
  }
  
  subgraph cluster_1 {
    label="monkey-model";
    node [shape = box];
    Monkey; Tree; Banana; monkeyOwns [shape = diamond; label="owns"];
  }

  Eater -> Monkey [abel=""; arrowtail=onormal; arrowhead=diamond; dir=both]
  Fruit -> Banana [label=""; arrowtail=onormal; arrowhead=diamond; dir=both; constraint=false]
  eaterOwns -> monkeyOwns [abel=""; arrowtail=onormal; arrowhead=diamond; dir=both]

  Monkey -> Tree [label="ownsTree"; arrowtail=diamond; arrowhead=vee; dir=both];

  Monkey -> monkeyOwns [label=""; arrowtail=diamond; arrowhead=none; dir=both];
  monkeyOwns -> Banana [label=""; arrowhead=vee];
  monkeyOwns -> Date [label=since; style=dotted; arrowtail=diamond; arrowhead=vee; dir=both; constraint=false];
  monkeyOwns -> Date [label=till; arrowtail=diamond; arrowhead=vee; dir=both; constraint=false];


  Eater -> Fruit [label=eats; arrowtail=diamond; arrowhead=vee; dir=both];
  Fruit -> Color [label=hasColor; arrowtail=diamond; arrowhead=vee; dir=both];
  Eater -> eaterOwns [label=""; arrowtail=diamond; arrowhead=none; dir=both];
  eaterOwns -> Fruit [label=owns; arrowhead=vee];
  eaterOwns -> Date [label=since; arrowtail=diamond; arrowhead=vee; dir=both];
}
```

```yaml
name: monkey-model
version: 1.0.0

includes:
  fm:
    name: fruit-model
    version: 1.0.0

classes:
  Monkey:
    super: fm.Eater            # fruit-model:Eater
    relations:
      ownsTree:                # monkey-model:ownsTree
        range: Tree
        modelKey: owns
        card: [0, 1]
      owns:                    # monkey-model:owns
        range: Banana
        modelKey: owns
        card: [0, n]

  owns:                        # monkey-model:owns
    super: fm.owns             # fruit-model:owns
    relations:
      till:
        range: fm.Date         # fruit-model:Date

  Banana:                      # monkey-model:Banana

  Tree:                        # monkey-model:Tree

  Fruit:                       # monkey-model:Fruit
    super: fm.Fruit            # fruit-model:Fruit
    relations:
      hasColor:
        range: Color

  Color:                       # monkey-model:Color

```
