export const isSatisfied = (remarks) => remarks === "satisfactory";
export const isUnsatisfied = (remarks) => remarks === "not_satisfactory";
export const isStudentOrRenter = (roles) => roles.length === 2 && roles.includes("student") && roles.includes("renter");


export const mergeSublessons = (sublessons, sublesson) => {
    return Object.entries(sublessons).reduce(
        (agg, [type, sublessons]) => {
            return {
                ...agg,
                [type]: sublessons.map((s) => {
                    if (s.id === sublesson.id) {
                        return sublesson
                    }
                    return s;
                }),
            };
        },
        {}
    );
}