---
title: "filter-map でコードの意図を明確にしよう"
emoji: "🕰️"
type: "tech"
topics: ["TypeScript"]
published: false
---
私は filter-map によるコーディングを好みます。

じゃない方は for-of です。

```TypeScript
function getEnemy(_id: number): {name: string; hp: number} {
    return {name: "ant", hp: 3};
}

const ids = [1, 2, 3, 4];

const enemies = [];
for (let id of ids) {
    if (id % 2) {
        enemies.push(getEnemy(id));
    }
}
```

for-of よりは下記のように filter-map します。

```TypeScript
function getEnemy(_id: number): {name: string; hp: number} {
    return {name: "ant", hp: 3};
}

const ids = [1, 2, 3, 4];

const enemies = ids
    .filter(id => id % 2)
    .map(getEnemy);
```

for-of の場合、読むときに次のようなデメリットがあります。

- enemies の宣言を見たときに、このあと何が起きるのかとワーキングメモリに入れておかないといけません。空配列のままではないはずですからね
- for と始まったときにこのあと何が起きるのか、と注意力を必要とします。for-of はいろいろなことをするために使われるからです

また for-of の場合は複数の意図を入れ込まれやすいです。totalHp が欲しいとなったときには次のように書かれると思います。

```TypeScript
const enemies = [];
let totalHp = 0;
for (let id of ids) {
    if (id % 2) {
        const enemy = getEnemy(id);
        totalHp += enemy.hp;
        enemies.push(enemy);
    }
}
```

filter-map 方式の場合は下のように書きます。

```TypeScript
const enemies = ids
    .filter(id => id % 2)
    .map(getEnemy);
const totalHp = enemies.reduce((acc, enemy) => acc + enemy.hp, 0);
```

totalHp が const になったため値の変化を追う必要がなくなりました。

for-of の場合は覚えておくことが多く、また、ブロック内部で何が行われているか注意深く見なくてはいけません。

filter-map の場合は、enemies 宣言の時点で、「この数行は enemies のためのコードだな」とわかります。enemies の生成に興味がない場合はコードを読むのを飛ばすことができます。対して for-of の場合はできません。ブロック内で何をしているか、確認しないとわからないためです。そういうわけで私は filter-map を好みます。
