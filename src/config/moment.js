export default {
    relativeTime: {
        past: function (input) {
        return input === 'just now'
            ? input
            : input + ' ago'
        },
        s: 'just now',
        future: 'in %s',
        m: '1m',
        mm: '%dm',
        h: '1h',
        hh: '%dh',
        d: '1d',
        dd: '%dd',
        M: '1 month',
        MM: '%d months',
        y: '1 year',
        yy: '%d years',
    }
};