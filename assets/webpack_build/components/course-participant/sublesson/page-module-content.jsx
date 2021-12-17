import React, { useEffect, useState } from "react";
import { Spinner } from "../common/spinner";

export const PageModuleContent = ({ pageModuleUrl }) => {
  const [state, setState] = useState({
    content: undefined,
    loading: true,
  });

  useEffect(() => {
    const getContent = () => {
      const reqOpts = {
        method: "GET",
      };

      fetch(pageModuleUrl, reqOpts)
        .then((res) => res.text())
        .then((data) => {
          setState((prevState) => ({
            ...prevState,
            loading: false,
            content: data,
          }));
        })
        .catch((error) => {
          console.log(error);
          setState((prevState) => ({
            ...prevState,
            loading: false,
          }));
        });
    };

    // load only html
    if (pageModuleUrl.includes(".html")) {
      getContent();
    } else {
      setTimeout(() => {
        setState((prevState) => ({
          ...prevState,
          loading: false,
        }));
      }, 1000);
    }
  }, [pageModuleUrl]);

  if (state.loading) {
    return (
      <div className="d-flex flex-row justify-content-center jumbotron mb-2">
        <Spinner />
      </div>
    );
  }

  if (!state.content) {
    return (
      <div className="sublesson module-content" style={{ minHeight: "280px" }}>
        <img src={pageModuleUrl} alt="asset" height="280px" />
      </div>
    );
  }

  return (
    <div
      className="sublesson module-content"
      dangerouslySetInnerHTML={{ __html: state.content }}
    />
  );
};
