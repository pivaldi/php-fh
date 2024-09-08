#!/usr/bin/php
<?php

foreach (get_defined_functions()['internal'] as $func) {
    echo $func . "\n";
}
