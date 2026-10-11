## godot web port template

you need [gdre tools](https://github.com/GDRETools/gdsdecomp/releases) for pack recovery and [godot](https://github.com/godotengine/godot/releases) 3.6.x or 4.3+ with matching web export templates installed.

`recover.sh` asks for your game folder or pck, gdre tools if needed, and any dlc packs. it puts the project in `work/project` and applies the default web patches. encrypted packs also ask for a key file and decryptor script

`build.sh` asks for godot. it makes `build/web` and `build/web-threads`

```bash
sh scripts/recover.sh
sh scripts/build.sh
```

paths are saved in gitignored `work/paths`. press enter to keep a saved path, or type `-` to clear it.

`build/web` is singlethreaded so it doesnt need headers

`build/web-threads` uses threads. serve it over https or localhost with these headers on every response

```
cross-origin-opener-policy: same-origin
cross-origin-embedder-policy: require-corp
```

## changes

make changes in `work/project`, then run

```bash
sh scripts/add-patch.sh
```

to name and add the patch