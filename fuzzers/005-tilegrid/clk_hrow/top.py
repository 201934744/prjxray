import os
import random
random.seed(int(os.getenv("SEED"), 16))
from prjxray import util
from prjxray.db import Database


def gen_sites():
    db = Database(util.get_db_root(), util.get_part())
    grid = db.grid()
    for tile_name in sorted(grid.tiles()):
        loc = grid.loc_of_tilename(tile_name)
        gridinfo = grid.gridinfo_at_loc(loc)
        sites = []
        for site, site_type in gridinfo.sites.items():
            if site_type == 'BUFHCE':
                sites.append(site)

        if sites:
            yield tile_name, sorted(sites)


def write_params(params):
    pinstr = 'tile,val,site\n'
    for tile, (site, val) in sorted(params.items()):
        pinstr += '%s,%s,%s\n' % (tile, val, site)
    open('params.csv', 'w').write(pinstr)


def run():
    print('''
module top();
    ''')

    params = {}

    sites = list(gen_sites())
    for (tile_name, sites), isone in zip(sites,
                                         util.gen_fuzz_states(len(sites))):
        site_name = sites[0]
        params[tile_name] = (site_name, isone)

        print(
            '''
            (* KEEP, DONT_TOUCH, LOC = "{site}" *)
            BUFHCE #(
                .INIT_OUT({isone})
                ) buf_{site} ();
'''.format(
                site=site_name,
                isone=isone,
            ))

    print("endmodule")
    write_params(params)


if __name__ == '__main__':
    run()
